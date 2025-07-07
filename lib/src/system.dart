import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/scheduler.dart' show FrameCallback;
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

BuildContext? activeContext;
FrameCallback? postFrameCallback;
bool shouldTriggerContextEffect = true;
bool shouldForceTrigger = false;

final contextEffect = Expando<Effect>("oref context effect");
final hooksCallIndex = Expando<int>("oref hooks call index");
final hooks = Expando<List<Object>>("oref hooks");

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
  final (exists, _) = resolveHookInstance<Signal<T>>(
    context,
    (e) => e is Signal && e.whereType<T>(),
  );
  if (exists != null) return exists.oper;

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
  hooks[context]!.add(instance);

  return instance.oper;
}

T Function() useComputed<T>(
  BuildContext context,
  T Function(T? prevValue) callback,
) {
  final (exists, _) = resolveHookInstance<Computed<T>>(
    context,
    (e) => e is Computed && e.whereType<T>(),
  );
  if (exists != null) return exists.oper;

  final oper = computed<T>((value) {
    final currentSub = getCurrentSub();
    final element = getCurrentContext() ?? context;
    if ((element is Element && !element.dirty) ||
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
  final instance = Computed<T>(oper);
  hooks[context]!.add(instance);

  return instance.oper;
}

VoidCallback useEffect(BuildContext context, VoidCallback callback) {
  final (exists, resetCallIndex) = resolveHookInstance<Effect>(
    context,
    (e) => e is Effect,
  );
  if (exists != null) return exists.stop;

  final prevContext = setCurrentContext(context);
  try {
    final container = hooks[context]!;
    final effect = createEffect(context, callback);
    container.add(effect);

    return effect.stop;
  } catch (_) {
    activeContext = prevContext;
    resetCallIndex();
    rethrow;
  }
}

VoidCallback useEffectScope(BuildContext context, VoidCallback callback) {
  final (scope, resetCallIndex) = resolveHookInstance<EffectScope>(
    context,
    (e) => e is EffectScope,
  );
  if (scope != null) return scope.stop;

  final prevContext = setCurrentContext(context);
  try {
    final stop = effectScope(callback);
    final scope = EffectScope(stop);
    hooks[context]!.add(scope);

    return stop;
  } catch (_) {
    resetCallIndex();
    rethrow;
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

    callback();
  });

  return Effect(node, stop);
}

void addPostFrameCallback(FrameCallback callback) {
  final prevCallback = postFrameCallback;
  if (prevCallback == null) {
    postFrameCallback = callback;
    WidgetsBinding.instance.addPostFrameCallback(
      debugLabel: 'oref post frame callback',
      (timeStamp) {
        postFrameCallback?.call(timeStamp);
        postFrameCallback = null;
      },
    );
    return;
  }

  postFrameCallback = (timeStamp) {
    prevCallback(timeStamp);
    callback(timeStamp);
  };
}

(T?, VoidCallback) resolveHookInstance<T extends Object>(
  BuildContext context,
  bool Function(Object) has,
) {
  final index = hooksCallIndex[context] ??= 0;
  if (index == 0) {
    addPostFrameCallback((_) => hooksCallIndex[context] = 0);
  }

  void reset() => hooksCallIndex[context] = index + 1;

  final container = hooks[context] ??= [];
  final hook = container.elementAtOrNull(index);

  if (hook != null && has(hook)) {
    return (hook as T, reset);
  } else if (hook == null && index < container.length) {
    container.length = index;
  }

  return (null, reset);
}

void triggerSignal(VoidCallback callback) {
  try {
    startBatch();
    shouldForceTrigger = true;
    callback();
  } finally {
    shouldForceTrigger = false;
    endBatch();
  }
}
