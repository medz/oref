import 'package:alien_signals/preset.dart' show setActiveSub;
import 'package:alien_signals/system.dart' show ReactiveNode;
import 'package:flutter/widgets.dart';

import 'widget_effect.dart';

/// Watch a signal in a widget.
///
/// Example:
/// ```dart
/// final count = signal(context, 0);
/// final value = watch(context, count);
/// ```
T watch<T>(BuildContext context, T Function() getter) {
  final effect = useWidgetEffect(context),
      prevSub = setActiveSub(effect as ReactiveNode);
  try {
    return getter();
  } finally {
    setActiveSub(prevSub);
  }
}
