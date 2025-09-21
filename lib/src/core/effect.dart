import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

import 'memoized.dart';
import 'widget_scope.dart';

void Function() effect(
  BuildContext context,
  void Function() run, {
  bool detach = false,
}) {
  return useMemoized(context, () {
    if (detach) {
      final prevScope = alien.setCurrentScope(null);
      final prevSub = alien.setCurrentSub(null);
      try {
        return alien.effect(run);
      } finally {
        alien.setCurrentScope(prevScope);
        alien.setCurrentSub(prevSub);
      }
    }

    if (alien.getCurrentScope() != null) {
      return alien.effect(run);
    }

    final scope = getWidgetScope(context);
    return scope.using(() => alien.effect(run));
  });
}
