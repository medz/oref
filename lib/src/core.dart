import 'package:flutter/widgets.dart';

BuildContext? _activeContext;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
BuildContext? getCurrentContext() => _activeContext;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
BuildContext? setCurrentContext(BuildContext? context) {
  final prev = _activeContext;
  _activeContext = context;

  return prev;
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
void markNeedsBuild(BuildContext context) {
  if (context is Element) context.markNeedsBuild();
}

final _voidCallbacks = Expando<void Function()>();

final _signals = Expando<void Function()>();
