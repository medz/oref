import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "widget_effect.dart";
import "widget_scope.dart";

final class _Mask<T> {
  const _Mask(this.computed);
  final T Function() computed;
}

T Function() computed<T>(
  BuildContext context,
  T Function(T? previousValue) getter,
) {
  final mask = useMemoized(context, () {
    final computed = alien.computed<T>(getter);
    return _Mask(() {
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
    });
  });

  return mask.computed;
}
