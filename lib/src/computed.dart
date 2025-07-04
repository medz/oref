import 'dart:developer' as developer;

import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'core.dart';
import 'effect.dart';

class Computed<T> {
  const Computed(this.oper);

  final T Function() oper;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool hasType<V>() => T == V;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Computed<R> cast<R>() => this as Computed<R>;
}

final computedIndices = Expando<int>("oref: computed indices");
final computeds = Expando<List<Computed>>("oref: computeds");

T Function() useComputed<T>(
  BuildContext context,
  T Function(T? previousValue) getter,
) {
  final index = computedIndices[context] ??= 0;
  if (index == 0) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      computedIndices[context] = 0;
    });
  }

  final store = computeds[context] ??= [];
  final exists = store.elementAtOrNull(index);
  if (exists != null) {
    if (exists.hasType<T>()) {
      computedIndices[context] = index + 1;
      return exists.cast<T>().oper;
    }

    // Otherwise, Type is not compatible with Comouted<T>
    // remove at current index computed and after computeds.
    store.length = index;
    developer.log("Type mismatch in useComputed<$T>", name: "oref", level: 900);
  }

  final oper = computed(getter);
  store.add(Computed<T>(oper));

  return () {
    if (context is Element && !context.dirty) {
      return oper();
    }

    final prevSub = getCurrentSub();
    final shouldTriggerContextEffect = getCurrentShouldTriggerContextEffect();
    if (shouldTriggerContextEffect && prevSub == null) {
      final effect = autoCreateContextEffect(context);
      setCurrentSub(effect.node);
      trackContextEffectOperation(context, oper);
    }

    try {
      return oper();
    } finally {
      if (shouldTriggerContextEffect) {
        setCurrentSub(prevSub);
      }
    }
  };
}
