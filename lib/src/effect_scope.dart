import 'package:alien_signals/alien_signals.dart';
import 'package:alien_signals/alien_signals.dart'
    as alien_signals
    show EffectScope;
import 'package:flutter/cupertino.dart';

import 'core.dart';

class EffectScope {
  const EffectScope({required this.stop, required this.node});

  final alien_signals.EffectScope node;
  final void Function() stop;
}

final contextScopeBindings = Expando<EffectScope>(
  'oref: Context scope bindings',
);

EffectScope autoCreateContextScope(BuildContext context) {
  final EffectScope? scope = contextScopeBindings[context];
  if (scope != null) return scope;

  final prevScope = setCurrentScope(null);
  final prevSub = setCurrentSub(null);

  try {
    late final alien_signals.EffectScope node;
    final stop = effectScope(() => node = getCurrentScope()!);

    return contextScopeBindings[context] = EffectScope(node: node, stop: stop);
  } finally {
    setCurrentScope(prevScope);
    setCurrentSub(prevSub);
  }
}

final effectScopeIndices = Expando<int>("oref: Effect scope indices");
final effectScopes = Expando<List<EffectScope>>("oref: Effect scopes");

VoidCallback useEffectScope(BuildContext context, VoidCallback callback) {
  final index = effectScopeIndices[context] ??= 0;
  if (index == 0) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      effectScopeIndices[context] = 0;
    });
  }

  final scopes = effectScopes[context] ??= [];
  final exists = scopes.elementAtOrNull(index);
  if (exists != null) {
    effectScopeIndices[context] = index + 1;
    return exists.stop;
  }

  final prevContext = setCurrentContext(context);
  final shouldSetScope = getCurrentScope() == null;
  final contextScope = autoCreateContextScope(context);
  if (shouldSetScope) setCurrentScope(contextScope.node);

  try {
    late final alien_signals.EffectScope node;
    final stop = effectScope(() {
      node = getCurrentScope()!;
      callback();
    });
    scopes.add(EffectScope(node: node, stop: stop));

    return stop;
  } finally {
    effectScopeIndices[context] = index + 1;
    setCurrentContext(prevContext);
    if (shouldSetScope) setCurrentScope(null);
  }
}
