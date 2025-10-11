import 'package:flutter/widgets.dart';

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

class _RootState {
  bool reset = true;
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
  final prev = _store[context] ??= _Memoized(value: _RootState()),
      current = prev.next,
      head = prev.head,
      state = head.value as _RootState;

  if (state.reset) {
    state.reset = false;
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      _store[context] = head;
      state.reset = true;
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

/// Resets the memoized value for the given context.
///
/// This will cause the next call to [useMemoized] to recompute the value.
void resetMemoizedFor(BuildContext context) {
  final head = _store[context]?.head, state = (head?.value as _RootState?);

  state?.reset = true;
  if (head != null) {
    head.next = null;
  }
  _store[context] = head;
}
