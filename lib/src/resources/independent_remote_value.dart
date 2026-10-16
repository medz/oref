part of 'resource.dart';

final class _IndependentRemoteValue<S, T> extends RemoteValue<S, T> {
  _IndependentRemoteValue({
    required S Function() source,
    this._identity,
    Seed<S, T>? initial,
    this._read,
    required FutureOr<T> Function(S, T) this._write,
  }) : _getSource = source,
       _seed = initial,
       _writeAck = null,
       super._() {
    _initializeSource();
  }

  _IndependentRemoteValue.ack({
    required S Function() source,
    this._identity,
    Seed<S, T>? initial,
    this._read,
    required FutureOr<void> Function(S, T) write,
  }) : _getSource = source,
       _seed = initial,
       _write = null,
       _writeAck = write,
       super._() {
    _initializeSource();
  }

  @override
  final _control = _ResourceControl();
  final _state = Value<RemoteState<S, T>>(RemoteState<S, T>._());
  late final _Source<({S source, Object? identity})> _source;
  S Function() _getSource;
  Object? Function(S)? _identity;
  Seed<S, T>? _seed;
  FutureOr<T> Function(S, ReadRequest)? _read;
  FutureOr<T> Function(S, T)? _write;
  FutureOr<void> Function(S, T)? _writeAck;
  bool _hasIdentity = false;
  Object? _currentIdentity;
  int _identityEpoch = 0;
  int _sourceEpoch = 0;
  bool _needsRead = false;
  _ReadOperation<T>? _activeRead;
  Future<T>? _attempt;
  Completer<T>? _activeWrite;

  void _initializeSource() {
    _source = _Source(
      source: _input,
      control: _control,
      changed: _sourceChanged,
      failed: _sourceFailed,
    );
  }

  ({S source, Object? identity}) _input() {
    final source = _getSource();
    final identity = _identity;
    return (
      source: source,
      identity: identity == null ? source : identity(source),
    );
  }

  @override
  Readable<RemoteState<S, T>> get state => _state;

  Future<T>? _resolve() {
    try {
      _control.check();
      if (_control.preparing) return _rejected(ResourceReason.busy);
      if (!_source.resolve()) {
        return Future<T>.error(_source.error!, _source.stackTrace);
      }
      _control.check();
      return null;
    } on Object catch (error, stackTrace) {
      return Future<T>.error(error, stackTrace);
    }
  }

  @override
  Future<T> ensureLoaded() {
    final failure = _resolve();
    if (failure != null) return failure;
    if (_control.writing) return _rejected(ResourceReason.busy);
    final current = _activeRead;
    if (current != null) return current.future;
    final attempt = _attempt;
    if (attempt != null) return attempt;
    if (_read == null) return _rejected(ResourceReason.notReady);
    return _startRead(ReadReason.initial);
  }

  @override
  Future<T> refresh() {
    final failure = _resolve();
    if (failure != null) return failure;
    if (_control.writing) return _rejected(ResourceReason.busy);
    if (_read == null) return _rejected(ResourceReason.noReader);
    return _activeRead?.future ?? _startRead(ReadReason.refresh);
  }

  Future<T> _startRead(ReadReason reason) {
    try {
      _control.check();
    } on Object catch (error, stackTrace) {
      return Future<T>.error(error, stackTrace);
    }
    final read = _read;
    if (read == null) return _rejected(ResourceReason.noReader);
    final input = _source.value;
    final operation = _ReadOperation<T>(reason);
    _activeRead = operation;
    _attempt = operation.future;
    final previous = _state.peek();
    _publish(
      _state,
      RemoteState<S, T>._(
        hasSource: true,
        source: input.source,
        hasValue: previous.hasValue,
        value: previous._value,
        loading: true,
      ),
    );
    scheduleMicrotask(() {
      if (!_isCurrentRead(operation)) return;
      try {
        _control.check();
      } on Object {
        _invalidateRead(ResourceReason.disposed);
        return;
      }
      if (!_isCurrentRead(operation)) return;
      Future<T>.sync(
        () => untracked(() => read(input.source, operation.request)),
      ).then<void>(
        (value) => _settleRead(operation, value: value),
        onError: (Object error, StackTrace stackTrace) =>
            _settleRead(operation, error: error, stackTrace: stackTrace),
      );
    });
    return operation.future;
  }

  bool _isCurrentRead(_ReadOperation<T> operation) =>
      !_control.closed &&
      identical(_activeRead, operation) &&
      !operation.finished;

  void _settleRead(
    _ReadOperation<T> operation, {
    T? value,
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      if (!_isCurrentRead(operation)) return;
      try {
        _control.check();
        _source.resolve();
      } on Object catch (failure, trace) {
        if (_isCurrentRead(operation)) {
          _activeRead = null;
          operation.failSource(failure, trace);
        }
        return;
      }
      if (!_isCurrentRead(operation)) {
        if (!_control.closed &&
            !_source.paused &&
            _source.hasValue &&
            !_control.writing &&
            _attempt == null &&
            _read != null) {
          _startRead(ReadReason.initial).ignore();
        }
        return;
      }
      _activeRead = null;
      final previous = _state.peek();
      _publish(
        _state,
        RemoteState<S, T>._(
          hasSource: true,
          source: _source.value.source,
          hasValue: error == null || previous.hasValue,
          value: error == null ? value : previous._value,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      if (error == null) {
        operation.complete(value as T);
      } else {
        operation.completeError(error, stackTrace!);
      }
    } finally {
      operation.finish();
    }
  }

  void _invalidateRead(ResourceReason reason) {
    final operation = _activeRead;
    _activeRead = null;
    operation?.invalidate(reason);
  }

  @override
  Future<T> set(T desired) => _change((_) => desired);

  @override
  Future<T> update(T Function(T) change) => _change(change);

  Future<T> _change(T Function(T) change) {
    final failure = _resolve();
    if (failure != null) return failure;
    if (_control.writing) return _rejected(ResourceReason.busy);
    final previous = _state.peek();
    if (!previous.hasValue) return _rejected(ResourceReason.notReady);
    final input = _source.value;
    final epoch = _identityEpoch;
    final sourceEpoch = _sourceEpoch;
    final before = previous.value;
    late T desired;
    var callbackFailed = false;
    _control.preparing = true;
    try {
      try {
        desired = untracked(() => change(before));
      } catch (_) {
        callbackFailed = true;
        rethrow;
      }
      _control.check();
      if (!_source.resolve() ||
          _source.value != input ||
          _identityEpoch != epoch ||
          _sourceEpoch != sourceEpoch) {
        return Future<T>.error(StateError('An update changed its source.'));
      }
    } on Object catch (error, stackTrace) {
      var qualified = false;
      if (callbackFailed && !_control.closed) {
        try {
          qualified =
              _source.resolve() &&
              _source.value == input &&
              _identityEpoch == epoch &&
              _sourceEpoch == sourceEpoch;
        } on Object {
          // Rechecking ownership must preserve this callback's original error.
        }
      }
      if (qualified && !_control.closed) {
        final current = _state.peek();
        _publish(
          _state,
          RemoteState<S, T>._(
            hasSource: current.hasSource,
            source: current._source,
            hasValue: current.hasValue,
            value: current._value,
            loading: current.loading,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
      return Future<T>.error(error, stackTrace);
    } finally {
      _control.preparing = false;
    }
    if (desired == before) return Future<T>.value(before);
    try {
      _control.beginWrite();
    } on Object catch (error, stackTrace) {
      return Future<T>.error(error, stackTrace);
    }
    final write = _write;
    final writeAck = _writeAck;
    final beforeAttempt = _activeRead == null ? _attempt : null;
    final previousRead = _activeRead;
    _activeRead = null;
    final operation = Completer<T>();
    _activeWrite = operation;
    _attempt = null;
    _needsRead = false;
    scheduleMicrotask(() {
      Future<T>.sync(() {
        if (write != null) {
          return untracked(() => write(input.source, desired));
        }
        return Future<void>.sync(
          () => untracked(() => writeAck!(input.source, desired)),
        ).then((_) => desired);
      }).then<void>(
        (value) => _settleWrite(
          operation,
          epoch,
          sourceEpoch,
          before,
          beforeAttempt,
          value: value,
        ),
        onError: (Object error, StackTrace stackTrace) => _settleWrite(
          operation,
          epoch,
          sourceEpoch,
          before,
          beforeAttempt,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    });
    Zone.current.runGuarded(
      () => batch(() {
        _publish(
          _state,
          RemoteState<S, T>._(
            hasSource: true,
            source: input.source,
            hasValue: true,
            value: desired,
            pending: true,
          ),
        );
        // Cancel callbacks may switch identity or close the resource. Publish the
        // accepted preview first, so no old preview can overwrite their state.
        previousRead?.invalidate(ResourceReason.superseded);
      }),
    );
    return operation.future;
  }

  void _settleWrite(
    Completer<T> operation,
    int epoch,
    int sourceEpoch,
    T before,
    Future<T>? beforeAttempt, {
    T? value,
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      if (!_control.closed) {
        try {
          _source.resolve();
        } on Object {
          // Namespace disposal cannot change the accepted writer's result.
        }
      }
      if (identical(_activeWrite, operation)) _activeWrite = null;
      Zone.current.runGuarded(
        () => batch(() {
          _control.endWrite();
          if (_control.closed) return;
          if (epoch == _identityEpoch && _source.hasValue) {
            final committed = error == null ? value as T : before;
            _attempt = error != null && sourceEpoch == _sourceEpoch
                ? beforeAttempt ?? Future<T>.value(before)
                : Future<T>.value(committed);
            _publish(
              _state,
              RemoteState<S, T>._(
                hasSource: true,
                source: _source.value.source,
                hasValue: true,
                value: committed,
                error: error,
                stackTrace: stackTrace,
              ),
            );
          } else {
            final current = _state.peek();
            _publish(
              _state,
              RemoteState<S, T>._(
                hasSource: current.hasSource,
                source: current._source,
                hasValue: current.hasValue,
                value: current._value,
                loading: current.loading,
                error: current.error,
                stackTrace: current.stackTrace,
              ),
            );
          }
          final needsRead = _needsRead;
          _needsRead = false;
          if (needsRead &&
              !_control.closed &&
              !_control.writing &&
              _source.hasValue &&
              _activeRead == null &&
              _read != null) {
            // Idle entries defer revalidation until their next explicit read.
            _attempt = null;
            if (!_source.paused) _startRead(ReadReason.initial).ignore();
          }
        }),
      );
    } finally {
      if (error == null) {
        operation.complete(value as T);
      } else {
        operation.completeError(error, stackTrace);
      }
    }
  }

  void _sourceChanged(bool automatic) {
    final sourceEpoch = ++_sourceEpoch;
    final input = _source.value;
    final sameIdentity = _hasIdentity && _currentIdentity == input.identity;
    _hasIdentity = true;
    _currentIdentity = input.identity;
    if (!sameIdentity) _identityEpoch++;
    final previousRead = _activeRead;
    _activeRead = null;
    _attempt = null;
    final previous = _state.peek();
    final seed = _seed;
    _seed = null;
    final useSeed = seed != null && seed.source == input.source;
    final hasValue = useSeed || sameIdentity && previous.hasValue;
    final value = useSeed
        ? seed.value
        : sameIdentity
        ? previous._value
        : null;
    if (useSeed || hasValue && _read == null) {
      _attempt = Future<T>.value(value as T);
    }
    if (_control.writing) _needsRead = _read != null;
    Zone.current.runGuarded(
      () => batch(() {
        _publish(
          _state,
          RemoteState<S, T>._(
            hasSource: true,
            source: input.source,
            hasValue: hasValue,
            value: value,
            pending: _control.writing,
          ),
        );
        previousRead?.invalidate(ResourceReason.sourceChanged);
      }),
    );
    if (automatic &&
        sourceEpoch == _sourceEpoch &&
        !_control.closed &&
        !_control.writing &&
        !_source.paused &&
        _source.hasValue &&
        _activeRead == null &&
        _attempt == null &&
        _read != null) {
      _startRead(ReadReason.initial).ignore();
    }
  }

  void _sourceFailed(Object error, StackTrace stackTrace) {
    _sourceEpoch++;
    _hasIdentity = false;
    _currentIdentity = null;
    _identityEpoch++;
    _seed = null;
    _attempt = null;
    _needsRead = false;
    final operation = _activeRead;
    _activeRead = null;
    Zone.current.runGuarded(
      () => batch(() {
        _publish(
          _state,
          RemoteState<S, T>._(
            pending: _control.writing,
            error: error,
            stackTrace: stackTrace,
          ),
        );
        operation?.failSource(error, stackTrace);
      }),
    );
  }

  @override
  T accept(Seed<S, T> authoritative) {
    _control.check();
    if (_control.preparing) {
      throw const ResourceException(ResourceReason.busy);
    }
    if (!_source.resolve()) {
      Error.throwWithStackTrace(_source.error!, _source.stackTrace!);
    }
    _control.check();
    if (_control.writing || _activeRead != null) {
      throw const ResourceException(ResourceReason.busy);
    }
    if (authoritative.source != _source.value.source) {
      throw const ResourceException(ResourceReason.sourceChanged);
    }
    _attempt = Future<T>.value(authoritative.value);
    _publish(
      _state,
      RemoteState<S, T>._(
        hasSource: true,
        source: _source.value.source,
        hasValue: true,
        value: authoritative.value,
      ),
    );
    return authoritative.value;
  }

  @override
  void dispose() {
    if (_control.closed) return;
    _control.close();
    _seed = null;
    _invalidateRead(ResourceReason.disposed);
    _source.dispose();
  }

  void _replace({
    required S Function() source,
    Object? Function(S)? identity,
    FutureOr<T> Function(S, ReadRequest)? read,
    FutureOr<T> Function(S, T)? write,
    FutureOr<void> Function(S, T)? writeAck,
  }) {
    if ((write == null) == (writeAck == null)) {
      throw ArgumentError('Provide exactly one writer.');
    }
    _getSource = source;
    _identity = identity;
    _read = read;
    _write = write;
    _writeAck = writeAck;
    _source.replace(_input);
  }
}
