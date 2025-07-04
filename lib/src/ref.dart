import 'package:flutter/widgets.dart';

import 'core.dart';
import 'signal.dart';

T Function() ref<T>(BuildContext context, T value) {
  final signal = useSignal(context, value);
  final prevShouldTriggerContextEffect = setShouldTriggerContextEffect(false);

  try {
    if (untrack(signal) != value) signal(value);
    return signal;
  } finally {
    setShouldTriggerContextEffect(prevShouldTriggerContextEffect);
  }
}
