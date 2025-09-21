import 'package:flutter/widgets.dart';

import 'widget_effect.dart';

extension SignalBuildContext on BuildContext {
  T watch<T>(T Function() getter) {
    final effect = getWidgetEffect(this);
    return effect.using(getter);
  }
}
