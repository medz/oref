import 'package:alien_signals/alien_signals.dart';

/// Batch execution of signals.
///
/// This function executes a batch of signals, ensuring that all signals are executed atomically.
///
/// Example:
/// ```dart
/// batch(() {
///   signal1.set("value1");
///   signal2.set("value2");
/// });
/// ```
T batch<T>(T Function() getter) {
  try {
    startBatch();
    return getter();
  } finally {
    endBatch();
  }
}
