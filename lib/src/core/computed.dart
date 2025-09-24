import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "widget_effect.dart";

final class _Mask<T> {
  const _Mask(this.computed);
  final T Function() computed;
}

/// Creates a reactive computed value that automatically tracks its dependencies.
///
/// Example:
/// ```dart
/// class DoubleCounter extends StatelessWidget {
///     Widget build() {
///         final count = signal(context, 0);
///         final doubleCount = computed(context, () => count() * 2);
///
///         void increment() => count(count() + 1);
///
///         return Column(
///             children: [
///                 Text("${doubleCount()}"),
///                 TextButton(
///                     onPressed: increment,
///                     child: const Text("Increment"),
///                 ),
///             ],
///         );
///     }
/// }
/// ```
T Function() computed<T>(
  BuildContext? context,
  T Function(T? previousValue) getter,
) {
  if (context == null) {
    return alien.computed(getter);
  }

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
