import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "widget_effect.dart";

final class _Mask<T> {
  const _Mask(this.computed);
  final T Function() computed;
}

T Function() computed<T>(
  BuildContext context,
  T Function(T? previousValue) getter,
) {
  final effect = useWidgetEffect(context);
  final mask = useMemoized(context, () {
    final computed = alien.computed(getter);
    return _Mask<T>(() {
      if (alien.getCurrentSub() == null && (context as Element).dirty) {
        return effect.using(computed);
      }

      return computed();
    });
  });

  return mask.computed;
}
