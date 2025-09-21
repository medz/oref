import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "widget_effect.dart";
import "widget_scope.dart";

class _Mask<T> {
  const _Mask(this.signal);
  final T Function([T?, bool]) signal;
}

T Function([T? value, bool nulls]) signal<T>(
  BuildContext context,
  T initialValue,
) {
  final mask = useMemoized(context, () {
    final signal = alien.signal<T>(initialValue);
    return _Mask<T>(([value, nulls = false]) {
      if (value is T && (value != null || (value == null && nulls))) {
        return signal(value, nulls);
      }

      if (alien.getCurrentSub() != null) {
        if (alien.getCurrentScope() != null) {
          return signal();
        }

        final scope = getWidgetScope(context);
        return scope.using(signal);
      }

      final effect = getWidgetEffect(context);
      if (alien.getCurrentScope() != null) {
        return effect.using(signal);
      }

      return effect.scopedUsing(context, signal);
    });
  });

  return mask.signal;
}
