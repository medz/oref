part of 'resource.dart';

/// An immutable snapshot of one source's latest read and model.
final class QueryState<S, T> {
  const QueryState._({
    this.hasSource = false,
    this._source,
    this.hasValue = false,
    this._value,
    this.pending = false,
    this.error,
    this.stackTrace,
  });

  final bool hasSource;
  final S? _source;
  final bool hasValue;
  final T? _value;
  final bool pending;
  final Object? error;
  final StackTrace? stackTrace;

  S get source {
    if (!hasSource) throw StateError('No source is available');
    return _source as S;
  }

  T get value {
    if (!hasValue) throw StateError('No value is available');
    return _value as T;
  }
}

/// A source-driven read with cached attempts and optional writable fields.
final class Query<S, T> {
  Query({required S Function() source, required this._load}) {
    _source = _Source(
      source: source,
      control: _control,
      changed: _sourceChanged,
      failed: _sourceFailed,
    );
  }

  final _control = _ResourceControl();
  late final _Source<S> _source;
  FutureOr<T> Function(S, ReadRequest) _load;
  final _state = Value<QueryState<S, T>>(const QueryState._());
  final _views = <_QueryFieldBase<S, T>>{};
  _ReadOperation<T>? _read;
  Future<T>? _attempt;
  int _epoch = 0;
  bool _needsRead = false;

  Readable<QueryState<S, T>> get state => _state;

  Future<T> ensureLoaded() => _loadCurrent(false);
  Future<T> refresh() => _loadCurrent(true);

  Future<T> _loadCurrent(bool refresh) {
    try {
      _control.check();
      if (_control.preparing) return _rejected(ResourceReason.busy);
      if (!_source.resolve()) {
        return Future.error(_source.error!, _source.stackTrace);
      }
      if (_control.writing) return _rejected(ResourceReason.busy);
      final active = _read;
      if (active != null) return active.future;
      if (!refresh && _attempt != null) return _attempt!;
      return _start(refresh ? ReadReason.refresh : ReadReason.initial);
    } catch (error, stack) {
      return Future.error(error, stack);
    }
  }

  Future<T> _start(ReadReason reason) {
    _control.check();
    final source = _source.value;
    final epoch = _epoch;
    final loader = _load;
    final operation = _ReadOperation<T>(reason);
    _read = operation;
    _attempt = operation.future;
    final before = _state.peek();
    _emit(
      QueryState._(
        hasSource: true,
        source: source,
        hasValue: before.hasValue,
        value: before._value,
        pending: true,
      ),
    );
    scheduleMicrotask(() {
      if (!_current(operation, epoch)) return;
      Future<T>.sync(() => untracked(() => loader(source, operation.request)))
          .then<void>(
            (value) => _finish(operation, epoch, value: value),
            onError: (Object error, StackTrace stack) =>
                _finish(operation, epoch, error: error, stack: stack),
          );
    });
    return operation.future;
  }

  bool _current(_ReadOperation<T> operation, int epoch) {
    if (_control.closed || _read != operation || _epoch != epoch) return false;
    try {
      _control.check();
      return !_control.closed && _read == operation && _epoch == epoch;
    } on Object {
      return false;
    }
  }

  void _finish(
    _ReadOperation<T> operation,
    int epoch, {
    T? value,
    Object? error,
    StackTrace? stack,
  }) {
    if (!_current(operation, epoch)) return;
    if (!_source.resolve() || !_current(operation, epoch)) {
      if (!_control.closed &&
          !_source.paused &&
          _source.hasValue &&
          !_control.writing &&
          _attempt == null) {
        _start(ReadReason.initial).ignore();
      }
      return;
    }
    _read = null;
    final before = _state.peek();
    try {
      _emit(
        QueryState._(
          hasSource: true,
          source: _source.value,
          hasValue: error == null || before.hasValue,
          value: error == null ? value : before._value,
          error: error,
          stackTrace: stack,
        ),
        readSucceeded: error == null,
      );
    } finally {
      if (error == null) {
        operation.complete(value as T);
      } else {
        operation.completeError(error, stack!);
      }
    }
  }

  void _sourceChanged(bool automatic) {
    final epoch = ++_epoch;
    final previous = _read;
    _read = null;
    _attempt = null;
    _needsRead = _control.writing;
    _emit(QueryState._(hasSource: true, source: _source.value));
    previous?.invalidate(ResourceReason.sourceChanged);
    if (automatic &&
        !_control.closed &&
        !_control.writing &&
        epoch == _epoch &&
        _source.hasValue &&
        _read == null &&
        _attempt == null) {
      _start(ReadReason.initial).ignore();
    }
  }

  void _sourceFailed(Object error, StackTrace stack) {
    _epoch++;
    final previous = _read;
    _read = null;
    _attempt = null;
    _needsRead = _control.writing;
    _emit(QueryState._(error: error, stackTrace: stack));
    previous?.failSource(error, stack);
  }

  void _emit(QueryState<S, T> snapshot, {bool readSucceeded = false}) {
    if (_control.closed) return;
    final epoch = _epoch;
    Zone.current.runGuarded(
      () => batch(() {
        _state.value = snapshot;
        if (_views.isEmpty) return;
        for (final view in _views.toList(growable: false)) {
          if (_control.closed ||
              _epoch != epoch ||
              !identical(_state.peek(), snapshot)) {
            break;
          }
          view.refreshState(snapshot, readSucceeded: readSucceeded);
        }
      }),
    );
  }

  RemoteValue<S, V> field<V>({
    required V Function(T) select,
    required T Function(T, V) apply,
    required FutureOr<V> Function(S, V) write,
  }) => _field(select: select, apply: apply, write: write);

  RemoteValue<S, V> fieldAck<V>({
    required V Function(T) select,
    required T Function(T, V) apply,
    required FutureOr<void> Function(S, V) write,
  }) => _field(select: select, apply: apply, writeAck: write);

  RemoteValue<S, V> _field<V>({
    required V Function(T) select,
    required T Function(T, V) apply,
    FutureOr<V> Function(S, V)? write,
    FutureOr<void> Function(S, V)? writeAck,
  }) {
    _control.check();
    final view = _QueryField<S, T, V>(this, select, apply, write, writeAck);
    _views.add(view);
    view.refreshState(_state.peek());
    return view;
  }

  Future<V> _writeField<V>(
    _QueryField<S, T, V> view,
    V Function(V)? change,
    V? desired,
  ) {
    var callbackFailed = false;
    int? preparedEpoch;
    try {
      view._check();
      if (_control.preparing) return _rejected(ResourceReason.busy);
      if (!_source.resolve()) {
        return Future.error(_source.error!, _source.stackTrace);
      }
      if (_control.writing) return _rejected(ResourceReason.busy);
      final before = _state.peek();
      final fieldBefore = view._state.peek();
      if (!before.hasValue || change != null && !fieldBefore.hasValue) {
        return _rejected(ResourceReason.notReady);
      }
      final epoch = _epoch;
      preparedEpoch = epoch;
      final input = _source.value;
      late V next;
      late T preview;
      _control.preparing = true;
      try {
        try {
          next = change == null
              ? desired as V
              : untracked(() => change(fieldBefore.value));
        } catch (_) {
          callbackFailed = true;
          rethrow;
        }
        if (!_source.resolve() || epoch != _epoch) {
          throw StateError('A field update changed its source');
        }
        view._check();
        if (fieldBefore.hasValue && fieldBefore.value == next) {
          return Future.value(next);
        }
        try {
          preview = untracked(() => view._apply(before.value, next));
        } catch (_) {
          callbackFailed = true;
          rethrow;
        }
        if (!_source.resolve() || epoch != _epoch) {
          throw StateError('A field update changed its source');
        }
        view._check();
        _control.beginWrite();
      } finally {
        _control.preparing = false;
      }
      final interrupted = _read;
      final rollbackAttempt = interrupted != null
          ? Future<T>.value(before.value)
          : _attempt ?? Future<T>.value(before.value);
      _read = null;
      _attempt = rollbackAttempt;
      view._writeError = null;
      view._writeStack = null;
      _emit(
        QueryState._(
          hasSource: true,
          source: input,
          hasValue: true,
          value: preview,
          error: before.error,
          stackTrace: before.stackTrace,
        ),
      );
      interrupted?.invalidate(ResourceReason.superseded);
      final result = Completer<V>();
      final writer = view._write;
      final ack = view._writeAck;
      scheduleMicrotask(() {
        Future<V>.sync(
          () => untracked(() async {
            if (ack != null) {
              await ack(input, next);
              return next;
            }
            return await writer!(input, next);
          }),
        ).then<void>(
          (canonical) => _finishField(
            view,
            epoch,
            before,
            rollbackAttempt,
            preview,
            canonical,
            ack != null,
            result,
          ),
          onError: (Object error, StackTrace stack) => _finishField(
            view,
            epoch,
            before,
            rollbackAttempt,
            preview,
            next,
            ack != null,
            result,
            error: error,
            stack: stack,
          ),
        );
      });
      return result.future;
    } catch (error, stack) {
      var qualified = false;
      if (callbackFailed && !view._disposed && !_control.closed) {
        try {
          _control.check();
          qualified = _source.resolve() && preparedEpoch == _epoch;
        } on Object {
          // Source/owner checks cannot replace the callback's original error.
        }
      }
      if (qualified && !view._disposed && !_control.closed) {
        view._writeError = error;
        view._writeStack = stack;
        view.refreshState(_state.peek());
      }
      return Future.error(error, stack);
    }
  }

  void _finishField<V>(
    _QueryField<S, T, V> view,
    int epoch,
    QueryState<S, T> before,
    Future<T> rollbackAttempt,
    T preview,
    V canonical,
    bool acknowledged,
    Completer<V> result, {
    Object? error,
    StackTrace? stack,
  }) {
    var qualified = false;
    T? committed;
    try {
      if (!_control.closed) {
        try {
          _control.check();
          qualified = _source.resolve() && epoch == _epoch;
        } on Object {
          qualified = false;
        }
      }
      if (qualified && error == null) {
        try {
          committed = acknowledged
              ? preview
              : untracked(() => view._apply(before.value, canonical));
        } catch (failure, trace) {
          error = failure;
          stack = trace;
        }
        try {
          qualified = _source.resolve() && epoch == _epoch;
        } on Object {
          qualified = false;
        }
      }
      if (qualified) {
        final value = error == null ? committed as T : before.value;
        _attempt = error == null ? Future.value(value) : rollbackAttempt;
        // The accepted writer's errors are its actual result, even when it
        // delegates to another resource which rejects with ResourceException.
        view._writeError = error;
        view._writeStack = stack;
        _control.endWrite();
        if (!_control.closed) {
          _emit(
            QueryState._(
              hasSource: true,
              source: _source.value,
              hasValue: true,
              value: value,
              error: before.error,
              stackTrace: before.stackTrace,
            ),
          );
        }
      } else {
        final needsRead = _needsRead;
        _needsRead = false;
        _control.endWrite();
        if (!_control.closed) {
          if (needsRead && _source.hasValue && !_source.paused) {
            _start(ReadReason.initial).ignore();
          } else {
            _emit(_state.peek());
          }
        }
      }
    } finally {
      if (error == null) {
        result.complete(canonical);
      } else {
        result.completeError(error, stack!);
      }
    }
  }

  void dispose() {
    if (_control.closed) return;
    _control.close();
    _source.dispose();
    _epoch++;
    final previous = _read;
    _read = null;
    previous?.invalidate(ResourceReason.disposed);
    for (final view in _views.toList(growable: false)) {
      view.closeFromParent();
    }
    _views.clear();
  }
}

void updateQuery<S, T>(
  Query<S, T> query, {
  required S Function() source,
  required FutureOr<T> Function(S, ReadRequest) load,
}) {
  query._load = load;
  query._source.replace(source);
}
