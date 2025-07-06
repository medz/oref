import 'package:alien_signals/alien_signals.dart';

import 'system.dart';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
T batch<T>(T Function() callback) {
  try {
    startBatch();
    return callback();
  } finally {
    endBatch();
  }
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
T untrack<T>(T Function() callback) {
  final prevSub = setCurrentSub(null);
  final prevShouldTriggerContextEffect = shouldTriggerContextEffect;
  shouldTriggerContextEffect = false;
  try {
    return callback();
  } finally {
    setCurrentSub(prevSub);
    shouldTriggerContextEffect = prevShouldTriggerContextEffect;
  }
}
