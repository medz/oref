import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

import 'memoized.dart';
import 'widget_scope.dart';

final class _Mask {
  const _Mask(this.stop);
  final void Function() stop;
}

void Function() effectScope(
  BuildContext context,
  void Function() run, {
  bool detach = false,
}) {
  final mask = useMemoized(context, () {
    if (detach) {
      final prevScope = alien.setCurrentScope(null);
      try {
        return _Mask(alien.effectScope(run));
      } finally {
        alien.setCurrentScope(prevScope);
      }
    } else if (alien.getCurrentScope() != null) {
      return _Mask(alien.effectScope(run));
    }

    final scope = useWidgetScope(context);
    return scope.using(() => _Mask(alien.effectScope(run)));
  });

  return mask.stop;
}
