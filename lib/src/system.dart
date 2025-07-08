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

class HookNode<T> {
  HookNode({required this.value, this.next});

  final T value;
  HookNode? next;
}

class HookState {
  HookNode? head;
  HookNode? current;
  bool isRendering = false;
}

BuildContext? activeContext;
bool shouldTriggerContextEffect = true;
bool withoutContext = false;

final contextEffect = Expando<Effect>("oref context effect");
final hooks = Expando<HookState>("oref hooks");

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

  // Initialize hook state if needed
  final hookState = hooks[context] ??= HookState();

  // Check if we need to start a new render cycle
  if (!hookState.isRendering) {
    hookState.isRendering = true;
    hookState.current = hookState.head;
    // Schedule reset for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hookState.current = null;
      hookState.isRendering = false;
    });
  }

  // Try to use existing hook at current position
  final currentNode = hookState.current;

  if (currentNode != null && currentNode.value is Signal<T>) {
    // Move to next position for subsequent hook calls
    hookState.current = currentNode.next;
    return (currentNode.value as Signal<T>).oper;
  }

  // Need to create new hook
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

  // Create new hook node
  final newNode = HookNode<Signal<T>>(value: instance);

  if (hookState.head == null) {
    // This is the very first hook
    hookState.head = newNode;
    // Don't move current - let the next hook call handle it
  } else if (currentNode == null) {
    // We're past the end of the existing hooks, append new one
    var last = hookState.head!;
    while (last.next != null) {
      last = last.next!;
    }
    last.next = newNode;
  }

  return instance.oper;
}

T Function() useComputed<T>(
  BuildContext context,
  T Function(T? prevValue) callback,
) {
  if (withoutContext) return computed(callback);

  // Initialize hook state if needed
  final hookState = hooks[context] ??= HookState();

  // Check if we need to start a new render cycle
  if (!hookState.isRendering) {
    hookState.isRendering = true;
    hookState.current = hookState.head;
    // Schedule reset for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hookState.current = null;
      hookState.isRendering = false;
    });
  }

  // Try to use existing hook at current position
  final currentNode = hookState.current;

  if (currentNode != null && currentNode.value is Computed<T>) {
    // Move to next position for subsequent hook calls
    hookState.current = currentNode.next;
    return (currentNode.value as Computed<T>).oper;
  }

  // Need to create new hook
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

  // Create new hook node
  final newNode = HookNode<Computed<T>>(value: instance);

  if (hookState.head == null) {
    // This is the very first hook
    hookState.head = newNode;
    // Don't move current - let the next hook call handle it
  } else if (currentNode == null) {
    // We're past the end of the existing hooks, append new one
    var last = hookState.head!;
    while (last.next != null) {
      last = last.next!;
    }
    last.next = newNode;
  }

  return instance.oper;
}

VoidCallback useEffect(BuildContext context, VoidCallback callback) {
  if (withoutContext) return effect(callback);

  // Initialize hook state if needed
  final hookState = hooks[context] ??= HookState();

  // Check if we need to start a new render cycle
  if (!hookState.isRendering) {
    hookState.isRendering = true;
    hookState.current = hookState.head;
    // Schedule reset for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hookState.current = null;
      hookState.isRendering = false;
    });
  }

  // Try to use existing hook at current position
  final currentNode = hookState.current;

  if (currentNode != null && currentNode.value is Effect) {
    // Move to next position for subsequent hook calls
    hookState.current = currentNode.next;
    return (currentNode.value as Effect).stop;
  }

  // Need to create new hook
  final prevContext = setCurrentContext(context);
  try {
    final effectInstance = createEffect(context, callback);

    // Create new hook node
    final newNode = HookNode<Effect>(value: effectInstance);

    if (hookState.head == null) {
      // This is the very first hook
      hookState.head = newNode;
      // Don't move current - let the next hook call handle it
    } else if (currentNode == null) {
      // We're past the end of the existing hooks, append new one
      var last = hookState.head!;
      while (last.next != null) {
        last = last.next!;
      }
      last.next = newNode;
    }

    return effectInstance.stop;
  } catch (_) {
    activeContext = prevContext;
    rethrow;
  }
}

VoidCallback useEffectScope(BuildContext context, VoidCallback callback) {
  if (withoutContext) return effectScope(callback);

  // Initialize hook state if needed
  final hookState = hooks[context] ??= HookState();

  // Check if we need to start a new render cycle
  if (!hookState.isRendering) {
    hookState.isRendering = true;
    hookState.current = hookState.head;
    // Schedule reset for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hookState.current = null;
      hookState.isRendering = false;
    });
  }

  // Try to use existing hook at current position
  final currentNode = hookState.current;

  if (currentNode != null && currentNode.value is EffectScope) {
    // Move to next position for subsequent hook calls
    hookState.current = currentNode.next;
    return (currentNode.value as EffectScope).stop;
  }

  // Need to create new hook
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

    // Create new hook node
    final newNode = HookNode<EffectScope>(value: scope);

    if (hookState.head == null) {
      // This is the very first hook
      hookState.head = newNode;
      // Don't move current - let the next hook call handle it
    } else if (currentNode == null) {
      // We're past the end of the existing hooks, append new one
      var last = hookState.head!;
      while (last.next != null) {
        last = last.next!;
      }
      last.next = newNode;
    }

    return scope.stop;
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
