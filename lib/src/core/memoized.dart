import 'package:flutter/widgets.dart';

class _Memoized<T> {
  _Memoized({
    required this.value,
    _Memoized? head,
    _Memoized? tail,
    this.next,
    this.prev,
  }) {
    this.head = head ?? this;
  }

  final T value;

  _Memoized? next;
  _Memoized? prev;

  late _Memoized head;

  bool valueOf<V>() => value is V;
}

final _store = Expando<_Memoized>("oref:memoized");
final _ticks = Expando<int>("oref:tikes");

BuildContext? _activeContext;

// BuildContext? getCurrentContext() => _activeContext;
// BuildContext? setCurrentContext(BuildContext? context) {
//   final prevContext = _activeContext;
//   _activeContext = context;
//   return prevContext;
// }

T useMemoized<T>(BuildContext context, T Function() factory) {
  final prevTick = _ticks[context] ??= 0;
  final tick = _tick(context);

  if (prevTick != tick) {
    _store[context] = _store[context]?.head;
  }

  _activeContext = context;
  final prev = _store[context], current = prev?.next;

  if (current == null &&
      prev != null &&
      prev.prev == null &&
      prev.valueOf<T>()) {
    return prev.value;
  }

  if (current != null && current.valueOf<T>()) {
    _store[context] = current;
    return current.value;
  }

  final memoized = _Memoized(value: factory(), prev: prev, head: prev?.head);
  if (prev != null) prev.next = memoized;

  _store[context] = memoized;
  return memoized.value;
}

int _tick(BuildContext context) {
  final tick = _ticks[context] ??= 0;

  if (context == _activeContext) return tick;
  return _ticks[context] = tick + 1;
}
