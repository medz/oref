import 'package:flutter/widgets.dart';

class _ElementDisposer {
  _ElementDisposer(this.element, this.dispose);

  final WeakReference<Element> element;
  final VoidCallback dispose;
}

final Set<_ElementDisposer> _trackedDisposers = <_ElementDisposer>{};
bool _frameCallbackInstalled = false;

void registerElementDisposer(BuildContext context, VoidCallback dispose) {
  if (context is! Element) return;

  _ensureFrameCallback();
  _trackedDisposers.add(
    _ElementDisposer(WeakReference<Element>(context), dispose),
  );
}

void _ensureFrameCallback() {
  if (_frameCallbackInstalled) return;
  _frameCallbackInstalled = true;

  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPersistentFrameCallback(_handleFrame);
}

void _handleFrame(Duration _) {
  if (_trackedDisposers.isEmpty) return;

  _trackedDisposers.removeWhere((entry) {
    final element = entry.element.target;
    if (element == null) {
      return true;
    }

    if (!element.mounted) {
      entry.dispose();
      return true;
    }

    return false;
  });
}
