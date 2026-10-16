import 'package:alien_signals/preset.dart' as alien;

/// Groups synchronous changes using the kernel's effect batching.
R batch<R>(R Function() changes) {
  alien.startBatch();
  try {
    return changes();
  } finally {
    alien.endBatch();
  }
}
