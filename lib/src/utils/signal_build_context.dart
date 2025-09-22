import 'package:flutter/widgets.dart';

import '../core/widget_effect.dart';

extension SignalBuildContext on BuildContext {
  T watch<T>(T Function() getter) {
    final effect = useWidgetEffect(this);
    return effect.using(getter);
  }
}
