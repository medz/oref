import 'package:flutter/widgets.dart';

BuildContext? _activeContext;
BuildContext? getActiveContext() => _activeContext;
BuildContext? setActiveContext(BuildContext? context) {
  _ensureInitializedReset();

  final prevContext = _activeContext;
  _activeContext = context;

  return prevContext;
}

bool _isInitialized = false;
void _ensureInitializedReset() {
  if (!_isInitialized) {
    _isInitialized = true;
    WidgetsFlutterBinding.ensureInitialized().addPersistentFrameCallback(
      _resetContextCallback,
    );
  }
}

void _resetContextCallback(_) {
  _activeContext = null;
}
