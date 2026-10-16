part of 'resource.dart';

/// The immutable result of an [Action].
class ActionState<R> {
  const ActionState._({
    this.pending = false,
    this.hasValue = false,
    this._value,
    this.error,
    this.stackTrace,
  });

  final bool pending;
  final bool hasValue;
  final Object? _value;
  final Object? error;
  final StackTrace? stackTrace;

  R get value {
    if (!hasValue) throw StateError('The action has no value.');
    return _value as R;
  }
}

/// An explicit write with one accepted operation at a time.
class Action<A, R> {
  Action({required this._execute});

  FutureOr<R> Function(A) _execute;
  final _control = _ResourceControl();
  final _state = Value<ActionState<R>>(ActionState<R>._());
  Completer<R>? _active;

  Readable<ActionState<R>> get state => _state;

  /// Starts a write, or returns a busy/disposed error without executing it.
  Future<R> run(A arguments) {
    try {
      _control.check();
      if (_active != null) {
        return Future<R>.error(const ResourceException(ResourceReason.busy));
      }
      _control.beginWrite();
    } on Object catch (error, stackTrace) {
      return Future<R>.error(error, stackTrace);
    }

    final operation = Completer<R>();
    final execute = _execute;
    _active = operation;
    // An accepted write must run even if a pending-state listener disposes it.
    scheduleMicrotask(() {
      Future<R>.sync(() => untracked(() => execute(arguments))).then<void>(
        (value) => _settle(operation, value: value),
        onError: (Object error, StackTrace stackTrace) =>
            _settle(operation, error: error, stackTrace: stackTrace),
      );
    });
    _publish(_state, ActionState<R>._(pending: true));
    return operation.future;
  }

  void _settle(
    Completer<R> operation, {
    Object? value,
    Object? error,
    StackTrace? stackTrace,
  }) {
    var mayPublish = !_control.closed;
    if (mayPublish) {
      try {
        _control.check();
      } on Object {
        // Shared ownership changes do not replace this writer's own result.
        mayPublish = false;
      }
    }
    if (identical(_active, operation)) _active = null;
    try {
      _control.endWrite();
      if (mayPublish && !_control.closed) {
        _publish(
          _state,
          error == null
              ? ActionState<R>._(hasValue: true, value: value)
              : ActionState<R>._(error: error, stackTrace: stackTrace),
        );
      }
    } finally {
      if (error == null) {
        operation.complete(value as R);
      } else {
        operation.completeError(error, stackTrace);
      }
    }
  }

  /// Prevents new operations; accepted writes keep their original result.
  void dispose() => _control.close();
}

/// Internal configuration hook for the owning Flutter adapter.
void updateAction<A, R>(
  Action<A, R> action, {
  required FutureOr<R> Function(A) execute,
}) {
  action._execute = execute;
}
