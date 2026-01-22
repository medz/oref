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

  final toRemove = <_ElementDisposer>[];
  final toDispose = <_ElementDisposer>[];

  for (final disposer in List<_ElementDisposer>.from(_trackedDisposers)) {
    final element = disposer.element.target;
    if (element == null) {
      toRemove.add(disposer);
      continue;
    }

    if (!element.mounted) {
      toRemove.add(disposer);
      toDispose.add(disposer);
    }
  }

  if (toRemove.isNotEmpty) {
    _trackedDisposers.removeWhere(toRemove.contains);
  }

  for (final disposer in toDispose) {
    disposer.dispose();
  }
}
