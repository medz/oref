import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

class Signal<T> {
  const Signal(this.oper);

  final T Function([T? value, bool nulls]) oper;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool whereType<V>() => T == V;
}

class Computed<T> {
  const Computed(this.oper);

  final T Function() oper;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool whereType<V>() => T == V;
}

class Effect {
  const Effect(this.node, this.stop);

  final ReactiveNode node;
  final void Function() stop;
}

class EffectScope {
  const EffectScope(this.stop);

  final void Function() stop;
}

class Hook<T> {
  Hook({required this.value, this.next, this.head, this.wasCreateNew = false});

  final T value;
  Hook? next;
  Hook? head;
  bool wasCreateNew;
}

BuildContext? activeContext;
bool shouldTriggerContextEffect = true;
bool withoutContext = false;

final contextEffect = Expando<Effect>("oref context effect");
final hooks = Expando<Hook>("oref hooks");

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
BuildContext? getCurrentContext() => activeContext;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
BuildContext? setCurrentContext(BuildContext? context) {
  final prev = activeContext;
  activeContext = context;

  return prev;
}

T Function([T? value, bool nulls]) useSignal<T>(
  BuildContext context,
  T initialValue,
) {
  if (withoutContext) return signal(initialValue);
  final hook = moveNextHook<Signal<T>>(context);
  if (hook != null) return hook.value.oper;

  final oper = signal(initialValue);
  final instance = Signal<T>(([value, nulls = false]) {
    if (value is T && (value != null || (value == null && nulls))) {
      return oper(value, nulls);
    }

    final currentSub = getCurrentSub();
    final element = getCurrentContext() ?? context;
    if ((element is Element && !element.dirty) ||
        currentSub != null ||
        !shouldTriggerContextEffect) {
      return oper(value, nulls);
    }

    try {
      setCurrentSub(getContextEffect(element).node);
      return oper();
    } finally {
      setCurrentSub(null);
    }
  });

  setNextHook(context, instance);

  return instance.oper;
}

T Function() useComputed<T>(
  BuildContext context,
  T Function(T? prevValue) callback,
) {
  if (withoutContext) return computed(callback);

  final hook = moveNextHook<Computed<T>>(context);
  if (hook != null) return hook.value.oper;

  final oper = computed<T>((value) {
    final prevWithoutContext = withoutContext;
    withoutContext = true;

    final currentSub = getCurrentSub();
    final element = getCurrentContext() ?? context;
    if ((element is Element && !element.dirty) ||
        currentSub != null ||
        !shouldTriggerContextEffect) {
      try {
        return callback(value);
      } finally {
        withoutContext = prevWithoutContext;
      }
    }

    final prevContext = setCurrentContext(element);
    try {
      setCurrentSub(getContextEffect(element).node);
      return callback(value);
    } finally {
      withoutContext = prevWithoutContext;
      setCurrentContext(prevContext);
      setCurrentSub(null);
    }
  });
  final instance = Computed<T>(oper);
  setNextHook(context, instance);

  return instance.oper;
}

VoidCallback useEffect(BuildContext context, VoidCallback callback) {
  if (withoutContext) return effect(callback);

  final hook = moveNextHook<Effect>(context);
  if (hook != null) return hook.value.stop;

  final prevContext = setCurrentContext(context);
  try {
    final effect = createEffect(context, callback);
    setNextHook(context, effect);

    return effect.stop;
  } catch (_) {
    activeContext = prevContext;
    rethrow;
  }
}

VoidCallback useEffectScope(BuildContext context, VoidCallback callback) {
  if (withoutContext) return effectScope(callback);
  final hook = moveNextHook<EffectScope>(context);
  if (hook != null) return hook.value.stop;

  final prevContext = setCurrentContext(context);
  try {
    final stop = effectScope(() {
      final prevWithoutContext = withoutContext;
      withoutContext = true;
      try {
        callback();
      } finally {
        withoutContext = prevWithoutContext;
      }
    });
    final scope = EffectScope(stop);
    setNextHook(context, scope);

    return stop;
  } finally {
    activeContext = prevContext;
  }
}

Effect getContextEffect(BuildContext context) {
  final effect = contextEffect[context];
  if (effect != null) return effect;

  final prevSub = setCurrentSub(null);
  try {
    final effect = createEffect(context, () {
      if (context is Element && !context.dirty) {
        context.markNeedsBuild();
      }
    });
    contextEffect[context] = effect;

    return effect;
  } finally {
    setCurrentSub(prevSub);
  }
}

Effect createEffect(BuildContext context, VoidCallback callback) {
  late final ReactiveNode node;
  bool firstRun = true;
  final stop = effect(() {
    if (firstRun) {
      firstRun = false;
      node = getCurrentSub()!;
    }

    final prevWithoutContext = withoutContext;
    withoutContext = true;
    try {
      callback();
    } finally {
      withoutContext = prevWithoutContext;
    }
  });

  return Effect(node, stop);
}

Hook<T>? moveNextHook<T>(BuildContext context) {
  final hook = hooks[context];
  final next = hook?.next;
  if (hook != null && hook.value is T && (next != null || !hook.wasCreateNew)) {
    if (hook == hook.head) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        hooks[context] = hook.head;
        for (var e = hook.head; e != null; e = e.next) {
          e.wasCreateNew = false;
        }
      });
    }

    if (next != null) {
      hooks[context] = next;
    } else {
      hook.wasCreateNew = true;
    }

    return hook as Hook<T>;
  }

  return null;
}

void setNextHook<T>(BuildContext context, T value) {
  final prevHook = hooks[context];
  final newHook = Hook(value: value, head: prevHook?.head);

  if (prevHook != null) {
    hooks[context] = prevHook.next = newHook;
  } else {
    newHook.head = newHook;
    hooks[context] = newHook;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hooks[context] = newHook;
    });
  }
}
