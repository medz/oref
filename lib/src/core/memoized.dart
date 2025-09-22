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
late Element activeElement;

T useMemoized<T>(BuildContext context, T Function() factory) {
  assert(context is Element, 'oref: The `context` must be an Element');
  activeElement = context as Element;

  assert(activeElement.dirty, "oref: Wrong use of memoization!");

  final prev = _store[context] ??= _Memoized(value: '<root>'),
      current = prev.next;

  if (current != null && current.valueOf<T>()) {
    _store[context] = current;
    return current.value;
  }

  final memoized = _Memoized(value: factory(), prev: prev, head: prev.head);
  prev.next = memoized;

  _store[context] = memoized;
  return memoized.value;
}

void resetMemoizedFor(BuildContext context) {
  _store[context] = _store[context]?.head;
}
