import 'package:flutter/widgets.dart';

import 'context.dart';

class _Memoized<T> {
  _Memoized({required this.value, this.next, this.prev, _Memoized? head}) {
    this.head = head ?? this;
  }

  final T value;

  _Memoized? next;
  _Memoized? prev;

  late _Memoized head;

  bool valueOf<V>() => value is V;

  @override
  toString() => "oref.Memoized(${value.toString()})";
}

class _RootMemoized extends _Memoized<BuildContext> {
  _RootMemoized(BuildContext context) : super(value: context);

  late bool reset = true;

  @override
  toString() => "oref.RootMemoized($value)";
}

final _store = Expando<_Memoized>("oref:memoized");

/// Memoizes a value for the given context.
///
/// The factory function is called only once per context, and the result is
/// cached for future use.
///
/// The memoized value can be reset by calling [resetMemoizedCursor].
///
/// Example:
/// ```dart
/// final value = useMemoized(context, () => expensiveComputation());
/// ```
T useMemoized<T>(BuildContext context, T Function() factory) {
  setActiveContext(context);

  final prev = _store[context] ??= _RootMemoized(context),
      current = prev.next,
      root = prev.head as _RootMemoized;

  if (root.reset) {
    root.reset = false;
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      _store[context] = root;
      root.reset = true;
    });
  }

  if (current != null && current.valueOf<T>()) {
    _store[context] = current;
    return current.value;
  }

  final memoized = _Memoized(value: factory(), prev: prev, head: prev.head);
  prev.next = memoized;

  _store[context] = memoized;
  return memoized.value;
}

/// {@template oref.resetMemoizedCursor}
/// Reset memoized cursor.
///
/// This will cause the next call to [useMemoized] to recompute the value.
/// {@endtemplate}
void resetMemoizedCursor(BuildContext context) {
  final root = _store[context]?.head as _RootMemoized?;
  root?.reset = true;
  _store[context] = root;
}
