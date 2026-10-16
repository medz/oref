part of 'resource.dart';

/// An authoritative value paired with the source it belongs to.
final class Seed<S, T> {
  const Seed({required this.source, required this.value});
  final S source;
  final T value;
}

final class RemoteState<S, T> {
  const RemoteState._({
    this.hasSource = false,
    this._source,
    this.hasValue = false,
    this._value,
    this.loading = false,
    this.pending = false,
    this.error,
    this.stackTrace,
  });

  final bool hasSource;
  final S? _source;
  final bool hasValue;
  final T? _value;
  final bool loading;
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

/// A writable remote value, independent or backed by a Query field.
abstract class RemoteValue<S, T> {
  factory RemoteValue({
    required S Function() source,
    Object? Function(S)? identity,
    Seed<S, T>? initial,
    FutureOr<T> Function(S, ReadRequest)? read,
    required FutureOr<T> Function(S, T) write,
  }) = _IndependentRemoteValue<S, T>;

  factory RemoteValue.ack({
    required S Function() source,
    Object? Function(S)? identity,
    Seed<S, T>? initial,
    FutureOr<T> Function(S, ReadRequest)? read,
    required FutureOr<void> Function(S, T) write,
  }) = _IndependentRemoteValue<S, T>.ack;

  RemoteValue._();

  _ResourceControl get _control;
  Readable<RemoteState<S, T>> get state;
  Future<T> ensureLoaded();
  Future<T> refresh();
  Future<T> set(T desired);
  Future<T> update(T Function(T) change);
  T accept(Seed<S, T> authoritative);
  void dispose();
}

abstract interface class _QueryFieldBase<S, M> {
  void refreshState(QueryState<S, M> parent, {bool readSucceeded = false});
  void closeFromParent();
}

final class _QueryField<S, M, V> extends RemoteValue<S, V>
    implements _QueryFieldBase<S, M> {
  _QueryField(
    this._parent,
    this._select,
    this._apply,
    this._write,
    this._writeAck,
  ) : super._();

  final Query<S, M> _parent;
  final V Function(M) _select;
  final M Function(M, V) _apply;
  final FutureOr<V> Function(S, V)? _write;
  final FutureOr<void> Function(S, V)? _writeAck;
  final _state = Value<RemoteState<S, V>>(const RemoteState._());
  bool _disposed = false;
  bool _projected = false;
  M? _projectedModel;
  V? _projectedValue;
  Object? _projectionError;
  StackTrace? _projectionStack;
  Object? _writeError;
  StackTrace? _writeStack;
  int _seenEpoch = -1;
  Future<M>? _parentAttempt;
  Completer<V>? _attempt;

  @override
  _ResourceControl get _control => _parent._control;
  @override
  Readable<RemoteState<S, V>> get state => _state;

  void _check() {
    if (_disposed) throw const ResourceException(ResourceReason.disposed);
    _control.check();
  }

  @override
  void refreshState(QueryState<S, M> parent, {bool readSucceeded = false}) {
    if (_disposed) return;
    if (_seenEpoch != _parent._epoch || readSucceeded) {
      _writeError = null;
      _writeStack = null;
      _seenEpoch = _parent._epoch;
    }
    if (parent.hasValue &&
        (!_projected || !identical(_projectedModel, parent.value))) {
      _projected = true;
      _projectedModel = parent.value;
      _projectionError = null;
      _projectionStack = null;
      try {
        _projectedValue = untracked(() => _select(parent.value));
      } catch (error, stack) {
        _projectedValue = null;
        _projectionError = error;
        _projectionStack = stack;
      }
    } else if (!parent.hasValue) {
      _projected = false;
      _projectedModel = null;
      _projectedValue = null;
      _projectionError = null;
      _projectionStack = null;
    }
    final error = _projectionError ?? _writeError ?? parent.error;
    _publish(
      _state,
      RemoteState._(
        hasSource: parent.hasSource,
        source: parent._source,
        hasValue: parent.hasValue && _projectionError == null,
        value: _projectedValue,
        loading: parent.pending,
        pending: _control.writing,
        error: error,
        stackTrace: _projectionError != null
            ? _projectionStack
            : _writeError != null
            ? _writeStack
            : parent.stackTrace,
      ),
    );
  }

  Future<V> _project(Future<M> parentFuture) {
    if (identical(_parentAttempt, parentFuture)) return _attempt!.future;
    final attempt = Completer<V>();
    _parentAttempt = parentFuture;
    _attempt = attempt;
    parentFuture.then<void>(
      (model) {
        if (attempt.isCompleted) return;
        try {
          _check();
          final V value;
          if (_projected && identical(_projectedModel, model)) {
            if (_projectionError != null) {
              Error.throwWithStackTrace(_projectionError!, _projectionStack!);
            }
            value = _projectedValue as V;
          } else {
            value = untracked(() => _select(model));
          }
          attempt.complete(value);
        } catch (error, stack) {
          attempt.completeError(error, stack);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!attempt.isCompleted) attempt.completeError(error, stack);
      },
    );
    return attempt.future;
  }

  @override
  Future<V> ensureLoaded() {
    try {
      _check();
      return _project(_parent.ensureLoaded());
    } catch (error, stack) {
      return Future.error(error, stack);
    }
  }

  @override
  Future<V> refresh() {
    try {
      _check();
      return _project(_parent.refresh());
    } catch (error, stack) {
      return Future.error(error, stack);
    }
  }

  @override
  Future<V> set(V desired) => _parent._writeField(this, null, desired);
  @override
  Future<V> update(V Function(V) change) =>
      _parent._writeField(this, change, null);

  @override
  V accept(Seed<S, V> authoritative) {
    _check();
    if (_control.preparing) throw const ResourceException(ResourceReason.busy);
    if (!_parent._source.resolve()) {
      Error.throwWithStackTrace(
        _parent._source.error!,
        _parent._source.stackTrace!,
      );
    }
    if (_control.writing || _parent._read != null) {
      throw const ResourceException(ResourceReason.busy);
    }
    if (authoritative.source != _parent._source.value) {
      throw const ResourceException(ResourceReason.sourceChanged);
    }
    final parent = _parent._state.peek();
    if (!parent.hasValue) {
      throw const ResourceException(ResourceReason.notReady);
    }
    final epoch = _parent._epoch;
    late M model;
    _control.preparing = true;
    try {
      model = untracked(() => _apply(parent.value, authoritative.value));
      _check();
      if (!_parent._source.resolve() || epoch != _parent._epoch) {
        throw const ResourceException(ResourceReason.sourceChanged);
      }
    } finally {
      _control.preparing = false;
    }
    _writeError = null;
    _writeStack = null;
    _parent._attempt = Future.value(model);
    _parent._emit(
      QueryState._(
        hasSource: true,
        source: _parent._source.value,
        hasValue: true,
        value: model,
        error: parent.error,
        stackTrace: parent.stackTrace,
      ),
    );
    return authoritative.value;
  }

  @override
  void closeFromParent() => dispose();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _parent._views.remove(this);
    _projectedModel = null;
    final attempt = _attempt;
    if (attempt != null && !attempt.isCompleted) {
      attempt.completeError(
        const ResourceException(ResourceReason.disposed),
        StackTrace.current,
      );
    }
  }
}

void updateRemoteValue<S, T>(
  RemoteValue<S, T> remote, {
  required S Function() source,
  Object? Function(S)? identity,
  FutureOr<T> Function(S, ReadRequest)? read,
  FutureOr<T> Function(S, T)? write,
  FutureOr<void> Function(S, T)? writeAck,
}) {
  if (remote case _IndependentRemoteValue<S, T>()) {
    remote._replace(
      source: source,
      identity: identity,
      read: read,
      write: write,
      writeAck: writeAck,
    );
  } else {
    throw StateError('A Query field inherits its parent configuration');
  }
}
