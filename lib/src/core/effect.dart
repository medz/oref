import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

import 'memoized.dart';
import 'widget_scope.dart';

final class _Mask {
  const _Mask(this.stop);
  final void Function() stop;
}

void Function() effect(
  BuildContext context,
  void Function() run, {
  bool detach = false,
}) {
  final mask = useMemoized(context, () {
    if (detach) {
      final prevScope = alien.setCurrentScope(null);
      final prevSub = alien.setCurrentSub(null);
      try {
        return _Mask(alien.effect(run));
      } finally {
        alien.setCurrentScope(prevScope);
        alien.setCurrentSub(prevSub);
      }
    }

    if (alien.getCurrentScope() != null) {
      return _Mask(alien.effect(run));
    }

    final scope = useWidgetScope(context);
    return scope.using(() => _Mask(alien.effect(run)));
  });

  return mask.stop;
}
