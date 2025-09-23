import 'package:flutter/widgets.dart';

import '../core/widget_effect.dart';

/// Watch a signal in a widget.
///
/// Example:
/// ```dart
/// final count = signal(context, 0);
/// final value = watch(context, count);
/// ```
T watch<T>(BuildContext context, T Function() getter) {
  final effect = useWidgetEffect(context);
  return effect.using(getter);
}
