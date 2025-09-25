import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

import '_utils.dart';
import 'lifecycle.dart';
import 'memoized.dart';
import 'widget_scope.dart';

final class _Mask {
  const _Mask(this.stop);
  final void Function() stop;
}

/// Creates a reactive effect that automatically tracks its dependencies and re-runs when they change.
///
/// An effect is a reactive computation that automatically tracks any reactive values (signals or computed values)
/// accessed during its execution. The effect will re-run whenever any of its tracked dependencies change.
///
/// The [run] function will be executed:
/// 1. Immediately when the effect is created
/// 2. Whenever any of its tracked dependencies change
///
/// Returns a cleanup function that can be called to dispose of the effect and stop tracking.
///
/// Example:
/// ```dart
/// final count = signal(context, 0);
/// final stop = effect(context, () {
///   print(count());
/// }); // Print 0
///
/// count(1); // Print 1
///
/// stop();
/// count(2); // No output
/// ```
void Function() effect(
  BuildContext? context,
  void Function() run, {
  bool detach = false,
}) {
  if (context == null && !detach) {
    final (stop, sub) = createEffect(run);
    return () {
      stop();
      triggerEffectStopCallback(sub);
    };
  } else if (context == null) {
    final prevScope = alien.setCurrentScope(null);
    final prevSub = alien.setCurrentSub(null);
    try {
      final (stop, sub) = createEffect(run);
      return () {
        stop();
        triggerEffectStopCallback(sub);
      };
    } finally {
      alien.setCurrentScope(prevScope);
      alien.setCurrentSub(prevSub);
    }
  }

  final mask = useMemoized(context, () {
    if (detach) {
      final prevScope = alien.setCurrentScope(null);
      final prevSub = alien.setCurrentSub(null);
      try {
        final (stop, sub) = createEffect(run);
        return _Mask(() {
          stop();
          triggerEffectStopCallback(sub);
        });
      } finally {
        alien.setCurrentScope(prevScope);
        alien.setCurrentSub(prevSub);
      }
    }

    if (alien.getCurrentScope() != null) {
      final (stop, sub) = createEffect(run);
      return _Mask(() {
        triggerEffectStopCallback(sub);
        stop();
      });
    }

    final scope = useWidgetScope(context);
    return scope.using(() {
      final (stop, sub) = createEffect(run);
      return _Mask(() {
        triggerEffectStopCallback(sub);
        stop();
      });
    });
  });

  return mask.stop;
}
