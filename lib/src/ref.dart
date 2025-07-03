import 'package:flutter/widgets.dart';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
T Function() ref<T>(BuildContext context, T value) {
  final signal = useSignal(context, value);
  if (signal() != value) signal(value);
  return signal;
}
