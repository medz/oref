import 'package:flutter/widgets.dart';

import '_element_disposer.dart';
import 'memoized.dart';

class _MountedToken {
  const _MountedToken();
}

class _UnmountedToken {
  const _UnmountedToken();
}

/// Run [callback] once after the widget is mounted.
///
/// The callback is scheduled for the end of the first frame and will not run
/// again for subsequent rebuilds of the same element.
void onMounted(BuildContext context, VoidCallback callback) {
  useMemoized<_MountedToken>(context, () {
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      final element = context is Element ? context : null;
      if (element == null || element.mounted) {
        callback();
      }
    });
    return const _MountedToken();
  });
}

/// Run [callback] once after the widget is unmounted.
void onUnmounted(BuildContext context, VoidCallback callback) {
  useMemoized<_UnmountedToken>(context, () {
    registerElementDisposer(context, callback);
    return const _UnmountedToken();
  });
}
