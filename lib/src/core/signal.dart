import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "widget_effect.dart";

class _Mask<T> {
  const _Mask(this.signal);
  final T Function([T?, bool]) signal;
}

T Function([T? value, bool nulls]) signal<T>(
  BuildContext context,
  T initialValue,
) {
  final effect = useWidgetEffect(context);
  final mask = useMemoized(context, () {
    final signal = alien.signal<T>(initialValue);
    return _Mask<T>(([value, nulls = false]) {
      if (alien.getCurrentSub() == null && activeElement.dirty) {
        return effect.using(() => signal(value, nulls));
      }

      return signal(value, nulls);
    });
  });

  return mask.signal;
}
