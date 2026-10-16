part of 'shared.dart';

/// An explicitly bounded resource directory for one current namespace.
final class Resources {
  Resources({
    required Object? Function() namespace,
    required this.maxIdle,
    required this.retain,
  }) : _namespaceSource = namespace {
    if (maxIdle < 0) {
      throw ArgumentError.value(maxIdle, 'maxIdle', 'Must not be negative.');
    }
    if (retain.isNegative) {
      throw ArgumentError.value(retain, 'retain', 'Must not be negative.');
    }
    _namespaceEffect = reactiveEffect(() {
      Object? next;
      Object? error;
      StackTrace? stackTrace;
      try {
        next = _namespaceSource();
      } catch (caught, stack) {
        error = caught;
        stackTrace = stack;
      }
      untracked(() => _adoptNamespace(next, error, stackTrace));
    });
  }

  final int maxIdle;
  final Duration retain;
  final Object? Function() _namespaceSource;
  final _entries = <_ResourceKey, _Entry>{};
  final _constructing = <(int, _ResourceKey)>{};
  final _idle = <_Entry>{};
  final _revision = Value<int>(0);
  final _clock = Stopwatch()..start();
  final _zone = Zone.current;
  late final Subscription _namespaceEffect;
  Object? _namespace;
  Object? _namespaceError;
  StackTrace? _namespaceStack;
  bool _hasNamespace = false;
  bool _disposed = false;
  int _generation = 0;
  Timer? _timer;
  int? _timerDeadline;

  bool get disposed => _disposed;

  /// Holds a resource until [callback] and its returned future finish.
  Future<T> use<R, T>(
    ResourceRef<R> ref,
    FutureOr<T> Function(R resource) callback,
  ) async {
    final borrowed = borrowResource(this, ref);
    try {
      return await callback(borrowed.value);
    } finally {
      borrowed.release();
    }
  }

  /// Closes the directory. Already accepted writes still settle normally.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _namespaceEffect.dispose();
    _cancelTimer();
    final entries = _entries.values.toList(growable: false);
    _entries.clear();
    _idle.clear();
    for (final entry in entries) {
      _retire(entry);
    }
    _clock.stop();
    _revision.value = _revision.peek() + 1;
  }

  void _adoptNamespace(Object? next, Object? error, StackTrace? stackTrace) {
    if (_disposed) return;
    final changed = error != null
        ? _namespaceError == null
        : !_hasNamespace || _namespaceError != null || next != _namespace;
    _namespaceError = error;
    _namespaceStack = stackTrace;
    if (!changed) return;
    _namespace = next;
    _hasNamespace = error == null;
    _generation++;
    _cancelTimer();
    final entries = _entries.values.toList(growable: false);
    _entries.clear();
    _idle.clear();
    for (final entry in entries) {
      _retire(entry);
    }
    _revision.value = _revision.peek() + 1;
  }

  void _checkNamespace() {
    if (_disposed) {
      throw const ResourceException(ResourceReason.disposed);
    }
    Object? next;
    Object? error;
    StackTrace? stackTrace;
    try {
      next = untracked(_namespaceSource);
    } catch (caught, stack) {
      error = caught;
      stackTrace = stack;
    }
    _adoptNamespace(next, error, stackTrace);
    if (_namespaceError case final error?) {
      Error.throwWithStackTrace(error, _namespaceStack!);
    }
  }

  void _checkEntry(_Entry entry) {
    _checkNamespace();
    if (entry.retired || entry.generation != _generation) {
      throw const ResourceException(ResourceReason.sourceChanged);
    }
  }

  _Entry _entry(ResourceRef<Object?> ref) {
    _checkNamespace();
    _expireIdle();
    // Family cleanup is user code and may itself change the namespace.
    _checkNamespace();
    final key = _ResourceKey(ref._definition, ref._key);
    final cached = _entries[key];
    if (cached != null) return cached;

    final generation = _generation;
    final creation = (generation, key);
    if (!_constructing.add(creation)) {
      throw StateError('A Family cannot recursively create its own key.');
    }
    try {
      return _createEntry(ref, key, generation);
    } finally {
      _constructing.remove(creation);
    }
  }

  _Entry _createEntry(
    ResourceRef<Object?> ref,
    _ResourceKey key,
    int generation,
  ) {
    final resource = untracked(() => ref._definition._createResource(ref._key));
    if (resource == null) {
      throw ArgumentError('A Family must create an Oref resource.');
    }
    late ResourceLifecycle lifecycle;
    try {
      lifecycle = resourceLifecycle(resource);
    } catch (_) {
      // The factory owns cleanup, including unsupported returned objects.
      _disposeCreated(ref._definition, resource);
      rethrow;
    }
    final entry = _Entry(key, resource, lifecycle, generation);
    var bound = false;
    try {
      lifecycle.bindShared(
        checkOwner: () => _checkEntry(entry),
        onWriteStart: () {
          _checkEntry(entry);
          entry.writes++;
          _idle.remove(entry);
          entry.deadline = null;
          _scheduleExpiry();
        },
        onWriteEnd: () {
          if (entry.writes > 0) entry.writes--;
          if (!entry.retired && entry.users == 0 && entry.writes == 0) {
            _makeIdle(entry);
          }
        },
      );
      // A factory may transfer an instance whose write was already accepted.
      // Its eventual endWrite uses these hooks and must match this initial pin.
      if (lifecycle.writing) entry.writes = 1;
      bound = true;
      _checkEntry(entry);
      _entries[key] = entry;
      return entry;
    } catch (_) {
      if (bound) {
        _evict(entry);
      } else {
        // A failed binding may be an instance owned by another directory.
        // Do not pause or dispose that directory's resource.
        if (identical(_entries[key], entry)) _entries.remove(key);
        entry.retired = true;
      }
      _scheduleExpiry();
      rethrow;
    }
  }

  void _release(_Entry entry) {
    entry.users--;
    if (entry.retired || entry.users != 0) return;
    try {
      entry.lifecycle.pauseSource();
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
    if (entry.writes == 0) _makeIdle(entry);
  }

  void _makeIdle(_Entry entry) {
    if (entry.retired || entry.users != 0 || entry.writes != 0) return;
    if (_disposed || maxIdle == 0 || retain == Duration.zero) {
      _evict(entry);
      _scheduleExpiry();
      return;
    }
    entry.deadline = _clock.elapsedMicroseconds + retain.inMicroseconds;
    _idle.remove(entry);
    _idle.add(entry);
    while (_idle.length > maxIdle) {
      _evict(_idle.first);
    }
    _scheduleExpiry();
  }

  void _expireIdle() {
    final now = _clock.elapsedMicroseconds;
    while (_idle.isNotEmpty && _idle.first.deadline! <= now) {
      _evict(_idle.first);
    }
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    if (_disposed || _idle.isEmpty) {
      _cancelTimer();
      return;
    }
    final deadline = _idle.first.deadline!;
    if (_timer != null && _timerDeadline == deadline) return;
    _cancelTimer();
    _timerDeadline = deadline;
    final remaining = deadline - _clock.elapsedMicroseconds;
    _timer = Timer(Duration(microseconds: remaining < 0 ? 0 : remaining), () {
      _timer = null;
      _timerDeadline = null;
      _expireIdle();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _timerDeadline = null;
  }

  void _evict(_Entry entry) {
    if (entry.retired) return;
    if (identical(_entries[entry.key], entry)) _entries.remove(entry.key);
    _idle.remove(entry);
    _retire(entry);
  }

  void _retire(_Entry entry) {
    if (entry.retired) return;
    entry.retired = true;
    entry.views.clear();
    try {
      entry.lifecycle.pauseSource();
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
    _disposeCreated(entry.key.definition, entry.resource);
  }

  void _disposeCreated(_ResourceDefinition definition, Object resource) {
    try {
      untracked(() => definition._disposeResource(resource));
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  void _report(Object error, StackTrace stackTrace) {
    // Cleanup of other entries must finish even if the error handler throws.
    _zone.scheduleMicrotask(() => _zone.handleUncaughtError(error, stackTrace));
  }
}

// Package-internal: Flutter borrows exactly one parent directory entry.
({R value, void Function() release}) borrowResource<R>(
  Resources resources,
  ResourceRef<R> ref,
) => untracked(() {
  final entry = resources._entry(ref);
  if (entry.lifecycle.disposed) {
    throw const ResourceException(ResourceReason.disposed);
  }
  resources._idle.remove(entry);
  entry.deadline = null;
  entry.users++;
  resources._scheduleExpiry();
  var released = false;
  void release() {
    if (released) return;
    released = true;
    resources._release(entry);
  }

  try {
    entry.lifecycle.resumeSource();
    resources._checkEntry(entry);
    final value = ref._resolve(entry.resource, entry.views);
    resources._checkEntry(entry);
    return (value: value, release: release);
  } catch (_) {
    release();
    rethrow;
  }
});

// Package-internal observable marker, including namespace failure/recovery.
Readable<int> resourcesRevision(Resources resources) => resources._revision;

final class _ResourceKey {
  const _ResourceKey(this.definition, this.key);
  final _ResourceDefinition definition;
  final Object? key;

  @override
  bool operator ==(Object other) =>
      other is _ResourceKey &&
      identical(definition, other.definition) &&
      key == other.key;

  @override
  int get hashCode => Object.hash(identityHashCode(definition), key);
}

final class _Entry {
  _Entry(this.key, this.resource, this.lifecycle, this.generation);
  final _ResourceKey key;
  final Object resource;
  final ResourceLifecycle lifecycle;
  final int generation;
  final views = Map<Object, Object?>.identity();
  int users = 0;
  int writes = 0;
  int? deadline;
  bool retired = false;
}
