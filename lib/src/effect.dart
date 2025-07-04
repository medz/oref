import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'core.dart';
import 'effect_scope.dart';

class Effect {
  const Effect({required this.node, required this.stop});

  final ReactiveNode node;
  final void Function() stop;
}

final contextEffectTrackedOpers = Expando<Set<VoidCallback>>(
  "oref: Context effect tracked opers",
);

void runContextEffectTrackedOpers(BuildContext context) {
  final opers = contextEffectTrackedOpers[context];
  if (opers == null || opers.isEmpty) return;
  for (final oper in opers) {
    oper();
  }
}

void trackContextEffectOperation(BuildContext context, VoidCallback oper) {
  (contextEffectTrackedOpers[context] ??= {}).add(oper);
}

final contextEffectBindings = Expando<Effect>("oref: Context effect bindings");

Effect autoCreateContextEffect(BuildContext context) {
  final Effect? e = contextEffectBindings[context];
  if (e != null) return e;

  final contextScope = autoCreateContextScope(context);
  final prevScope = setCurrentScope(contextScope.node);
  final prevSub = setCurrentSub(null);

  try {
    late final ReactiveNode node;
    bool firstRun = true;
    final stop = effect(() {
      runContextEffectTrackedOpers(context);
      if (firstRun) {
        firstRun = false;
        node = getCurrentSub()!;
      } else if (context is Element && !context.dirty) {
        context.markNeedsBuild();
      }
    });

    return contextEffectBindings[context] = Effect(node: node, stop: stop);
  } finally {
    setCurrentSub(prevSub);
    setCurrentScope(prevScope);
  }
}

final effectIndices = Expando<int>("oref: Effect indices");
final effects = Expando<List<Effect>>("oref: Effects");

VoidCallback useEffect(BuildContext context, VoidCallback callback) {
  final index = effectIndices[context] ??= 0;
  if (index == 0) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      effectIndices[context] = 0;
    });
  }

  final store = effects[context] ??= [];
  final exists = store.elementAtOrNull(index);
  if (exists != null) {
    effectIndices[context] = index + 1;
    return exists.stop;
  }

  final shouldSetScope = getCurrentScope() == null && getCurrentSub() == null;
  final contextScope = autoCreateContextScope(context);
  if (shouldSetScope) setCurrentScope(contextScope.node);

  try {
    late final ReactiveNode node;
    bool firstRun = true;
    final stop = effect(() {
      if (firstRun) {
        firstRun = false;
        node = getCurrentSub()!;
      }

      final prevContext = setCurrentContext(context);
      try {
        callback();
      } finally {
        setCurrentContext(prevContext);
      }
    });
    store.add(Effect(node: node, stop: stop));

    return stop;
  } finally {
    effectIndices[context] = index + 1;
    if (shouldSetScope) setCurrentScope(null);
  }
}
