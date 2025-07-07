import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'system.dart';

const createGlobalEffectScope = effectScope;
const createGlobalEffect = effect;

T Function([T? value, bool nulls]) createGlobalSignal<T>(T initialValue) {
  final oper = signal(initialValue);
  return ([value, nulls = false]) {
    if (value is T && (value != null || (value == null && nulls))) {
      return oper(value, nulls);
    }

    final currentSub = getCurrentSub();
    final element = getCurrentContext();
    if (element == null ||
        (element is Element && !element.dirty) ||
        currentSub != null ||
        !shouldTriggerContextEffect) {
      return oper(value, nulls);
    }

    try {
      setCurrentSub(getContextEffect(element).node);
      return oper(value, nulls);
    } finally {
      setCurrentSub(null);
    }
  };
}

T Function() createGlobalComputed<T>(T Function(T? prevValue) callback) {
  return computed((value) {
    final currentSub = getCurrentSub();
    final element = getCurrentContext();
    if (element == null ||
        (element is Element && !element.dirty) ||
        currentSub != null ||
        !shouldTriggerContextEffect) {
      return callback(value);
    }

    final prevContext = setCurrentContext(element);
    try {
      setCurrentSub(getContextEffect(element).node);
      return callback(value);
    } finally {
      setCurrentContext(prevContext);
      setCurrentSub(null);
    }
  });
}
