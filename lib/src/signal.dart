import 'dart:developer' as developer;

import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

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
    final contextEffect = autoCreateContextEffect(context);
    final demo = getCurrentSub() ?? contextEffect.node;
    final prevSub = setCurrentSub(getCurrentSub() ?? contextEffect.node);

    debugPrint('Getter, Current Sub, ${demo.hashCode}');

    try {
      return oper(value, nulls);
    } finally {
      setCurrentSub(prevSub);
    }
  };
}
