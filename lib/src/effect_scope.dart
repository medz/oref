import 'package:alien_signals/alien_signals.dart' hide EffectScope;
import 'package:alien_signals/alien_signals.dart'
    as alien_signals
    show EffectScope;
import 'package:flutter/cupertino.dart';

import 'core.dart';

class EffectScope {
  const EffectScope({required this.stop, required this.value});

  final alien_signals.EffectScope value;
  final void Function() stop;
}

final contextScopeBindings = Expando<EffectScope>(
  'oref: Context scope bindings',
);

EffectScope autoCreateContextScope(BuildContext context) {
  final EffectScope? scope = contextScopeBindings[context];
  if (scope != null) return scope;

  late final alien_signals.EffectScope value;
  final stop = effectScope(() => value = getCurrentScope()!);

  return contextScopeBindings[context] = EffectScope(value: value, stop: stop);
}

EffectScope? activeContextScope;
EffectScope? getCurrentContextScope() => activeContextScope;
EffectScope? setCurrentContextScope(EffectScope? scope) {
  final prevScope = getCurrentContextScope();
  activeContextScope = scope;

  return prevScope;
}

final effectScopes = Expando<List<EffectScope>>();
int effectScopeIndex = 0;

VoidCallback useEffectScope(BuildContext context, VoidCallback fn) {
  final isCurrentContext = context == getCurrentContext();
  final prevIndex = effectScopeIndex++;
  final scopes = effectScopes[context] ?? <EffectScope>[];
  if (!isCurrentContext) effectScopeIndex = 0;

  final exists = scopes.elementAtOrNull(effectScopeIndex);
  if (exists != null) return exists.stop;

  final parentScope = autoCreateContextScope(context);
  final prevScope = setCurrentScope(parentScope.value);
  final prevContext = setCurrentContext(context);

  try {
    late final alien_signals.EffectScope value;
    final stop = effectScope(() {
      value = getCurrentScope()!;
      fn();
    });
    scopes.add(EffectScope(value: value, stop: stop));

    return stop;
  } finally {
    setCurrentScope(prevScope);
    if (!isCurrentContext) {
      setCurrentContext(prevContext);
      effectScopeIndex = prevIndex;
    }
  }
}
