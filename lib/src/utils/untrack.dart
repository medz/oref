import 'package:alien_signals/alien_signals.dart';

/// Untracks the current subscription and returns the result of the getter.
///
/// Example:
/// ```dart
/// final value = untrack(count); // Does track the `count` signal.
/// ```
T untrack<T>(T Function() getter) {
  final prevSub = setCurrentSub(null);
  try {
    return getter();
  } finally {
    setCurrentSub(prevSub);
  }
}
