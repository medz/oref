import 'dart:developer' as developer;

import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'core.dart';
import 'effect.dart';

class Signal<T> {
  const Signal(this.oper);

  final T Function([T? value, bool nulls]) oper;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool hasType<V>() => T == V;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Signal<R> cast<R>() => this as Signal<R>;
}

final signalIndices = Expando<int>("oref: signal indices");
final signals = Expando<List<Signal>>("oref: signals");

T Function([T? value, bool nulls]) useSignal<T>(
  BuildContext context,
  T initialValue,
) {
  final index = signalIndices[context] ??= 0;
  if (index == 0) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      signalIndices[context] = 0;
    });
  }

  final store = signals[context] ??= [];
  final exists = store.elementAtOrNull(index);
  if (exists != null) {
    if (exists.hasType<T>()) {
      signalIndices[context] = index + 1;
      return exists.cast<T>().oper;
    }

    // Otherwise, Type is not compatible with Signal<T>
    // remove at current index signal and after signals.
    store.length = index;
    developer.log("Type mismatch in useSignal<$T>", name: "oref", level: 900);
  }

  final oper = signal<T>(initialValue);
  store.add(Signal<T>(oper));

  return ([value, nulls = false]) {
    if (context is Element && !context.dirty) {
      return oper(value, nulls);
    }

    final prevSub = getCurrentSub();
    final shouldTriggerContextEffect = getCurrentShouldTriggerContextEffect();
    if (shouldTriggerContextEffect && prevSub == null) {
      final effect = autoCreateContextEffect(context);
      setCurrentSub(effect.node);
      trackContextEffectOperation(context, oper);
    }

    try {
      return oper(value, nulls);
    } finally {
      if (shouldTriggerContextEffect) {
        setCurrentSub(prevSub);
      }
    }
  };
}

T untrack<T>(T Function() callback) {
  final prevSub = setCurrentSub(null);
  final prevShouldTriggerContextEffect = setShouldTriggerContextEffect(false);
  try {
    return callback();
  } finally {
    setCurrentSub(prevSub);
    setShouldTriggerContextEffect(prevShouldTriggerContextEffect);
  }
}
