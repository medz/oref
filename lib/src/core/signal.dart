import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "widget_effect.dart";

class _Mask<T> {
  const _Mask(this.signal);
  final T Function([T?, bool]) signal;
}

/// {@template oref.signal}
/// Creates a reactive signal with an initial value.
///
/// A signal is a reactive value container that notifies dependents when its
/// value changes. The returned function can be used to:
/// - Get the current value when called with no arguments
/// - Set a new value when called with a value argument
/// - Control whether null values should be treated as updates when [nulls] is true
/// {@endtemplate}
///
/// Example:
/// ```dart
/// final count = signal(context, 0);
/// count(); // get value
/// count(1); // set value
/// ```
T Function([T? value, bool nulls]) signal<T>(
  BuildContext context,
  T initialValue,
) {
  final effect = useWidgetEffect(context);
  final mask = useMemoized(context, () {
    final signal = alien.signal<T>(initialValue);
    return _Mask<T>(([value, nulls = false]) {
      if (alien.getCurrentSub() == null && (context as Element).dirty) {
        return effect.using(() => signal(value, nulls));
      }

      return signal(value, nulls);
    });
  });

  return mask.signal;
}
