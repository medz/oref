import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "widget_effect.dart";
import "widget_scope.dart";

T Function() computed<T>(
  BuildContext context,
  T Function(T? previousValue) getter,
) {
  return useMemoized<T Function()>(context, () {
    final computed = alien.computed<T>(getter);
    return () {
      if (alien.getCurrentSub() != null) {
        if (alien.getCurrentScope() != null) {
          return computed();
        }

        final scope = getWidgetScope(context);
        return scope.using(computed);
      }

      final effect = getWidgetEffect(context);
      if (alien.getCurrentScope() != null) {
        return effect.using(computed);
      }

      return effect.scopedUsing(context, computed);
    };
  });
}
