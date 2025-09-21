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

T useMemoized<T>(BuildContext context, T Function() factory) {
  final prev = _store[context], current = prev?.next;

  if (current == null &&
      prev != null &&
      prev.prev == null &&
      prev.valueOf<T>()) {
    return prev.value;
  } else if (current != null && current.valueOf<T>()) {
    _store[context] = current;
    return current.value;
  }

  final memoized = _Memoized(value: factory(), prev: prev, head: prev?.head);
  if (prev != null) prev.next = memoized;

  _store[context] = memoized;
  return memoized.value;
}

void resetMemoized(BuildContext context) {
  _store[context] = _store[context]?.head;
}
