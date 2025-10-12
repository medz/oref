import 'package:alien_signals/alien_signals.dart';

import 'context.dart';

/// Untracks the current subscription and returns the result of the getter.
///
/// Example:
/// ```dart
/// final value = untrack(count); // Does track the `count` signal.
/// ```
T untrack<T>(T Function() getter) {
  final prevSub = setActiveSub(null), prevContext = setActiveContext(null);
  try {
    return getter();
  } finally {
    setActiveSub(prevSub);
    setActiveContext(prevContext);
  }
}
