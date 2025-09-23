import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

import 'memoized.dart';
import 'widget_scope.dart';

final class _Mask {
  const _Mask(this.stop);
  final void Function() stop;
}

/// {@template oref.effect-scope}
/// Creates a new effect scope that can be used to group and manage multiple effects.
///
/// An effect scope provides a way to collectively manage the lifecycle of effects.
/// When the scope is disposed by calling the returned cleanup function, all effects
/// created within the scope are automatically disposed as well.
///
/// The [run] function will be executed immediately within the new scope context.
/// Any effects created during this execution will be associated with this scope.
///
/// Returns a cleanup function that can be called to dispose of the scope and all
/// effects created within it.
/// {@endtemplate}
void Function() effectScope(
  BuildContext? context,
  void Function() run, {
  bool detach = false,
}) {
  if (context == null && !detach) {
    return alien.effectScope(run);
  } else if (context == null) {
    final prevScope = alien.setCurrentScope(null);
    try {
      return alien.effectScope(run);
    } finally {
      alien.setCurrentScope(prevScope);
    }
  }

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
