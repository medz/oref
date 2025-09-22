import 'package:alien_signals/alien_signals.dart';

T batch<T>(T Function() getter) {
  try {
    startBatch();
    return getter();
  } finally {
    endBatch();
  }
}
