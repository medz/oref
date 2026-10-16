part of 'resource.dart';

enum ReadReason { initial, refresh, append }

abstract interface class ReadRequest {
  ReadReason get reason;
  bool get cancelled;
  Subscription onCancel(void Function() cancel);
}

final class _CallbackSubscription implements Subscription {
  _CallbackSubscription(this._cancel);
  void Function()? _cancel;

  @override
  void dispose() {
    final cancel = _cancel;
    _cancel = null;
    cancel?.call();
  }
}

final class _ReadRequest implements ReadRequest {
  _ReadRequest(this.reason);

  @override
  final ReadReason reason;
  @override
  bool cancelled = false;
  bool _ended = false;
  int _nextId = 0;
  final _callbacks = <int, ({Zone zone, void Function() callback})>{};

  @override
  Subscription onCancel(void Function() cancel) {
    if (cancelled) {
      Zone.current.runGuarded(cancel);
      return _CallbackSubscription(null);
    }
    if (_ended) return _CallbackSubscription(null);
    final id = _nextId++;
    _callbacks[id] = (zone: Zone.current, callback: cancel);
    return _CallbackSubscription(() => _callbacks.remove(id));
  }

  void _cancel() {
    if (cancelled || _ended) return;
    cancelled = true;
    final pending = _callbacks.values.toList(growable: false);
    _callbacks.clear();
    for (final item in pending.reversed) {
      item.zone.runGuarded(item.callback);
    }
  }

  void _finish() {
    _ended = true;
    _callbacks.clear();
  }
}

final class _ReadOperation<T> {
  _ReadOperation(ReadReason reason) : request = _ReadRequest(reason);
  final _ReadRequest request;
  final _completer = Completer<T>();
  Future<T> get future => _completer.future;
  bool get finished => _completer.isCompleted;

  void complete(T value) {
    if (finished) return;
    request._finish();
    _completer.complete(value);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (finished) return;
    request._finish();
    _completer.completeError(error, stackTrace);
  }

  void invalidate(ResourceReason reason) {
    if (finished) return;
    _completer.completeError(ResourceException(reason), StackTrace.current);
    request._cancel();
    request._finish();
  }

  void failSource(Object error, StackTrace stackTrace) {
    if (finished) return;
    _completer.completeError(error, stackTrace);
    request._cancel();
    request._finish();
  }

  void finish() => request._finish();
}
