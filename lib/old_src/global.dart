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
    
    // Only skip dependency tracking if already in a reactive context
    if (currentSub != null) {
      return oper(value, nulls);
    }
    
    // If we have a context, set up dependency tracking
    if (element != null) {
      try {
        setCurrentSub(getContextEffect(element).node);
        return oper(value, nulls);
      } finally {
        setCurrentSub(null);
      }
    }
    
    // No context available, just return the value
    return oper(value, nulls);
  };
}

T Function() createGlobalComputed<T>(T Function(T? prevValue) callback) {
  return computed((value) {
    final currentSub = getCurrentSub();
    final element = getCurrentContext();
    
    // For global computed, only skip dependency tracking if already in a reactive context
    if (currentSub != null) {
      return callback(value);
    }
    
    // If we have a context, set up dependency tracking
    if (element != null) {
      final prevContext = setCurrentContext(element);
      try {
        setCurrentSub(getContextEffect(element).node);
        return callback(value);
      } finally {
        setCurrentContext(prevContext);
        setCurrentSub(null);
      }
    }
    
    // No context available, execute without tracking (this is expected for truly global computed)
    return callback(value);
  });
}
