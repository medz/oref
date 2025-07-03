import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'effect_scope.dart';

class Effect {
  const Effect({required this.sub, required this.stop});

  final ReactiveNode sub;
  final void Function() stop;
}

final contextEffectBindings = Expando<Effect>("oref: Context effect bindings");
Effect? autoCreateContextEffect(BuildContext context) {
  final Effect? e = contextEffectBindings[context];
  if (e != null) return e;

  final scope = autoCreateContextScope(context);
  final prevScope = setCurrentScope(scope.value);

  try {
    late final ReactiveNode sub;
    bool firstRun = true;
    final stop = effect(() {
      if (firstRun) {
        sub = getCurrentSub()!;
        firstRun = false;
      } else if (context is Element && !context.dirty) {
        context.markNeedsBuild();
      }
    });

    return contextEffectBindings[context] = Effect(sub: sub, stop: stop);
  } finally {
    setCurrentScope(prevScope);
  }
}
