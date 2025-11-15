import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/system.dart' as alien;
import 'package:alien_signals/preset.dart' as alien;
import 'package:flutter/widgets.dart';

import '_warn.dart';
import 'memoized.dart';
import 'widget_scope.dart';

typedef EffectScope = alien.EffectScope;

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
EffectScope effectScope(
  BuildContext? context,
  void Function() callback, {
  bool detach = false,
}) {
  if (context == null) {
    return _createEffectScope(callback: callback, detach: detach);
  }

  return useMemoized(context, () {
    final currentSub = alien.getActiveSub();
    if (currentSub != null || detach) {
      return _createEffectScope(
        callback: callback,
        detach: detach,
        context: context,
      );
    }

    final scope = useWidgetScope(context);
    final prevSub = alien.setActiveSub(scope as alien.ReactiveNode);
    try {
      return _createEffectScope(
        callback: callback,
        context: context,
        detach: false,
      );
    } finally {
      alien.setActiveSub(prevSub);
    }
  });
}

void onScopeDispose(void Function() callback, {bool failSilently = false}) {
  final sub = alien.getActiveSub();
  if (sub is _OrefEffectScope) {
    sub.onDispose = callback;
  } else if (!failSilently) {
    warn('onScopeDispose called outside of an effect scope');
  }
}

_OrefEffectScope _createEffectScope({
  required void Function() callback,
  required bool detach,
  BuildContext? context,
}) {
  final scope = _OrefEffectScope(), prevSub = alien.setActiveSub(scope);
  if (context != null) {
    _OrefEffectScope.finalizer.attach(context, scope, detach: scope);
  }

  if (prevSub != null && !detach) {
    alien.link(scope, prevSub, 0);
  }

  try {
    callback();
    return scope;
  } finally {
    alien.setActiveSub(prevSub);
  }
}

class _OrefEffectScope extends alien.ReactiveNode implements alien.EffectScope {
  static final finalizer = Finalizer<_OrefEffectScope>((scope) => scope());

  _OrefEffectScope() : super(flags: .none);

  void Function()? onDispose;

  @override
  void call() {
    onDispose?.call();
    onDispose = null;
    for (alien.Link? link = deps; link != null; link = link.nextDep) {
      switch (link.dep) {
        case alien.EffectScope scope:
          scope();
          break;
        case alien.Effect effect:
          effect();
          break;
        case alien.EffectNode node:
          alien.stop(node);
          break;
      }
    }

    alien.stop(this);
    finalizer.detach(this);
  }
}
