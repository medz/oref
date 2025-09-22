import 'package:flutter/widgets.dart';

import '../core/widget_effect.dart';

/// Signal utils on [BuildContext].
extension SignalBuildContext on BuildContext {
  /// Shortcut alias for `WidgetEffect.using`
  ///
  /// Example:
  /// ```dart
  /// final count = signal(context, count);
  /// final value = context.watch(count);
  /// ```
  T watch<T>(T Function() getter) {
    final effect = useWidgetEffect(this);
    return effect.using(getter);
  }
}
