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

/// Memoizes a value for the given context.
///
/// The factory function is called only once per context, and the result is
/// cached for future use.
///
/// The memoized value can be reset by calling [resetMemoizedFor].
///
/// Example:
/// ```dart
/// final value = useMemoized(context, () => expensiveComputation());
/// ```
T useMemoized<T>(BuildContext context, T Function() factory) {
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

/// Resets the memoized value for the given context.
///
/// This will cause the next call to [useMemoized] to recompute the value.
void resetMemoizedFor(BuildContext context) {
  _store[context] = _store[context]?.head;
}
