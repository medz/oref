import 'dart:async';

import '../core/alien_adapter.dart';
import '../core/batch.dart';
import '../core/readable.dart';
import '../core/subscription.dart';
import '../core/value.dart';

part 'action.dart';
part 'independent_remote_value.dart';
part 'pages.dart';
part 'query.dart';
part 'read_request.dart';
part 'remote_value.dart';

/// Conditions that prevent work or invalidate an unfinished read.
enum ResourceReason {
  busy,
  disposed,
  notReady,
  noReader,
  sourceChanged,
  superseded,
}

final class ResourceException implements Exception {
  const ResourceException(this.reason);

  final ResourceReason reason;

  @override
  String toString() => 'ResourceException(${reason.name})';
}

/// Package-internal integration with a shared resource directory.
abstract interface class ResourceLifecycle {
  bool get disposed;
  bool get writing;
  void bindShared({
    required void Function() checkOwner,
    required void Function() onWriteStart,
    required void Function() onWriteEnd,
  });
  void pauseSource();
  void resumeSource();
}

ResourceLifecycle resourceLifecycle(Object resource) => switch (resource) {
  Query() => resource._control,
  Pages() => resource._control,
  Action() => resource._control,
  RemoteValue() => resource._control,
  _ => throw ArgumentError.value(
    resource,
    'resource',
    'Expected an Oref resource',
  ),
};

bool resourceDisposed(Object resource) => switch (resource) {
  _QueryField() => resource._disposed || resource._control.closed,
  _ => resourceLifecycle(resource).disposed,
};

void disposeResource(Object resource) {
  switch (resource) {
    case Query():
      resource.dispose();
    case Pages():
      resource.dispose();
    case Action():
      resource.dispose();
    case RemoteValue():
      resource.dispose();
    default:
      throw ArgumentError.value(resource, 'resource');
  }
}

void activateResource(Object resource) {
  switch (resource) {
    case Query():
      resource.ensureLoaded().ignore();
    case Pages():
      resource.ensureLoaded().ignore();
    case RemoteValue():
      resource.ensureLoaded().ignore();
    case Action():
      break;
    default:
      throw ArgumentError.value(resource, 'resource');
  }
}

void _publish<T>(Value<T> target, T next) {
  Zone.current.runGuarded(() => target.value = next);
}

Future<T> _rejected<T>(ResourceReason reason) =>
    Future<T>.error(ResourceException(reason), StackTrace.current);

final class _ResourceControl implements ResourceLifecycle {
  bool closed = false;
  bool preparing = false;
  bool _writing = false;
  void Function()? pause;
  void Function()? resume;
  void Function()? _checkOwner;
  void Function()? _onWriteStart;
  void Function()? _onWriteEnd;

  @override
  bool get disposed => closed;
  @override
  bool get writing => _writing;

  void check() {
    if (closed) throw const ResourceException(ResourceReason.disposed);
    _checkOwner?.call();
    if (closed) throw const ResourceException(ResourceReason.disposed);
  }

  void beginWrite() {
    check();
    if (_writing) throw const ResourceException(ResourceReason.busy);
    _writing = true;
    try {
      _onWriteStart?.call();
    } catch (_) {
      _writing = false;
      rethrow;
    }
  }

  void endWrite() {
    if (!_writing) return;
    _writing = false;
    _onWriteEnd?.call();
  }

  void close() => closed = true;

  @override
  void bindShared({
    required void Function() checkOwner,
    required void Function() onWriteStart,
    required void Function() onWriteEnd,
  }) {
    check();
    if (_checkOwner != null) {
      throw StateError('Resource already has a shared owner');
    }
    _checkOwner = checkOwner;
    _onWriteStart = onWriteStart;
    _onWriteEnd = onWriteEnd;
  }

  @override
  void pauseSource() => pause?.call();
  @override
  void resumeSource() => resume?.call();
}

/// Tracks only synchronous source evaluation through the existing kernel.
final class _Source<S> {
  _Source({
    required S Function() source,
    required this._control,
    required this._changed,
    required this._failed,
  }) : _read = source {
    _control.pause = pause;
    _control.resume = resume;
  }

  S Function() _read;
  final _ResourceControl _control;
  final void Function(bool) _changed;
  final void Function(Object, StackTrace) _failed;
  ReactiveObserver? _observer;
  bool active = false;
  bool _paused = false;
  bool get paused => _paused;
  bool _resolving = false;
  bool hasValue = false;
  S? _value;
  Object? error;
  StackTrace? stackTrace;

  S get value {
    if (!hasValue) throw StateError('Source is unavailable');
    return _value as S;
  }

  bool resolve() {
    _control.check();
    active = true;
    return _evaluate(false);
  }

  bool _evaluate(bool automatic) {
    if (_resolving) {
      throw StateError('A source cannot recursively resolve itself');
    }
    _resolving = true;
    late S next;
    late bool changed;
    try {
      if (_paused) {
        next = untracked(_read);
      } else {
        _observer ??= ReactiveObserver(_invalidated);
        next = _observer!.track(_read);
      }
      changed = !hasValue || value != next;
    } catch (failure, stack) {
      hasValue = false;
      _value = null;
      error = failure;
      stackTrace = stack;
      _resolving = false;
      if (_control.closed) {
        error = const ResourceException(ResourceReason.disposed);
      } else {
        _failed(failure, stack);
        // A listener may recover the source synchronously. This resolve still
        // failed and must deliver its own original error, rather than null.
        error = failure;
        stackTrace = stack;
      }
      return false;
    }
    _resolving = false;
    try {
      _control.check();
    } catch (failure, stack) {
      error = failure;
      stackTrace = stack;
      return false;
    }
    hasValue = true;
    _value = next;
    error = null;
    stackTrace = null;
    if (changed) _changed(automatic);
    if (_control.closed) {
      error = const ResourceException(ResourceReason.disposed);
      stackTrace = StackTrace.current;
      return false;
    }
    return hasValue;
  }

  void _invalidated() {
    if (_control.closed || _paused || !active) return;
    try {
      _control.check();
    } on Object {
      return;
    }
    _evaluate(true);
  }

  void replace(S Function() source) {
    _read = source;
    if (active && !_paused && !_control.closed) {
      _control.check();
      _evaluate(true);
    }
  }

  void pause() {
    _paused = true;
    _observer?.dispose();
    _observer = null;
  }

  void resume() {
    if (!_paused || _control.closed) return;
    _paused = false;
    if (active) {
      _control.check();
      _evaluate(true);
    }
  }

  void dispose() {
    _observer?.dispose();
    _observer = null;
  }
}
