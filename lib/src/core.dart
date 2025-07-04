import 'package:flutter/widgets.dart';

BuildContext? activeContext;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
BuildContext? getCurrentContext() => activeContext;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
BuildContext? setCurrentContext(BuildContext? context) {
  final prev = activeContext;
  activeContext = context;

  return prev;
}

bool shouldTriggerContextEffect = true;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
bool getCurrentShouldTriggerContextEffect() => shouldTriggerContextEffect;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
bool setShouldTriggerContextEffect(bool value) {
  final prev = shouldTriggerContextEffect;
  shouldTriggerContextEffect = value;

  return prev;
}
