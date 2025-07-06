import 'package:flutter/widgets.dart';

import 'system.dart';
import 'utils.dart';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
T Function() ref<T>(BuildContext context, T value) {
  final signal = useSignal(context, value);
  final prevShouldTriggerContextEffect = shouldTriggerContextEffect;
  shouldTriggerContextEffect = false;

  try {
    if (untrack(signal) != value) signal(value);
    return signal;
  } finally {
    shouldTriggerContextEffect = prevShouldTriggerContextEffect;
  }
}
