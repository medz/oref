import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'warn.dart';

class LinkedBindingNode {
  LinkedBindingNode? next;
}

class Signal<T> extends LinkedBindingNode {
  Signal(this.oper);

  final T Function([T? value, bool nulls]) oper;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool whereType<V>() => T == V;
}

class Computed<T> extends LinkedBindingNode {
  Computed(this.oper);

  final T Function() oper;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool whereType<V>() => T == V;
}

class Effect extends LinkedBindingNode {
  Effect(this.node, this.stop);

  final ReactiveNode node;
  final void Function() stop;
}

class EffectScope extends LinkedBindingNode {
  EffectScope(this.stop);

  final void Function() stop;
}

class Bindings {
  LinkedBindingNode? headNode;
  LinkedBindingNode? tailNode;
  LinkedBindingNode? currentNode;
  Effect? effect;
  bool isRendering = false;
}

BuildContext? activeContext;
bool shouldTriggerContextEffect = true;
bool withoutContext = false;

final bindings = Expando<Bindings>("oref bindings");

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
Bindings findOrCreareBindings(BuildContext context) =>
    bindings[context] ??= Bindings();

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

/// Creates a signal that can be used within a Flutter widget.
///
/// The signal will automatically trigger rebuilds when its value changes,
/// but only if the widget is not already marked as dirty.
T Function([T? value, bool nulls]) useSignal<T>(
  BuildContext context,
  T initialValue,
) {
  final existing = moveNextBindingNode<Signal<T>>(context);
  if (existing != null) return existing.oper;

  // Create new signal
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

  linkBindingNode(context, instance);
  return instance.oper;
}

/// Creates a computed value that automatically updates when its dependencies change.
///
/// The computed value will be recalculated whenever any signal it reads changes,
/// and will trigger widget rebuilds when accessed outside of a reactive context.
T Function() useComputed<T>(
  BuildContext context,
  T Function(T? prevValue) callback,
) {
  final existing = moveNextBindingNode<Computed<T>>(context);
  if (existing != null) return existing.oper;

  // Create new computed
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
  linkBindingNode(context, instance);

  return instance.oper;
}

/// Creates an effect that runs whenever its dependencies change.
///
/// Returns a dispose function that should be called to stop the effect.
VoidCallback useEffect(BuildContext context, VoidCallback callback) {
  final existing = moveNextBindingNode<Effect>(context);
  if (existing != null) return existing.stop;

  // Create new effect
  final prevContext = setCurrentContext(context);
  try {
    final effect = createEffect(context, callback);
    linkBindingNode(context, effect);

    return effect.stop;
  } catch (_) {
    activeContext = prevContext;
    rethrow;
  }
}

/// Creates an effect scope that can contain multiple effects.
///
/// All effects created within the callback will be automatically disposed
/// when the returned dispose function is called.
VoidCallback useEffectScope(BuildContext context, VoidCallback callback) {
  final existing = moveNextBindingNode<EffectScope>(context);
  if (existing != null) return existing.stop;

  // Create new effect scope
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
    linkBindingNode(context, scope);

    return scope.stop;
  } finally {
    activeContext = prevContext;
  }
}

/// Gets or creates an effect that triggers widget rebuilds when signals change.
///
/// This effect is associated with the context and ensures that widgets
/// rebuild when reactive values they depend on change.
Effect getContextEffect(BuildContext context) {
  final bindings = findOrCreareBindings(context);
  final effect = bindings.effect;
  if (effect != null) return effect;

  final prevSub = setCurrentSub(null);
  try {
    final effect = createEffect(context, () {
      if (context is Element && !context.dirty) {
        context.markNeedsBuild();
      }
    });
    bindings.effect = effect;

    return effect;
  } finally {
    setCurrentSub(prevSub);
  }
}

/// Creates an effect that runs the callback within a reactive context.
///
/// The effect will automatically track dependencies and re-run when they change.
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

T? moveNextBindingNode<T>(BuildContext context) {
  if (withoutContext) return null;
  final bindings = findOrCreareBindings(context);

  if (!bindings.isRendering) {
    bindings.isRendering = true;
    bindings.currentNode = bindings.headNode;
    // Schedule reset for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bindings.currentNode = null;
      bindings.isRendering = false;
    });
  }

  final currentNode = bindings.currentNode;
  if (currentNode != null && currentNode is T) {
    // Move to next position for subsequent binding calls
    bindings.currentNode = currentNode.next;
    return currentNode as T;
  }

  return null;
}

void linkBindingNode<T extends LinkedBindingNode>(
  BuildContext context,
  T node,
) {
  if (withoutContext) return;
  final bindings = findOrCreareBindings(context);

  if (bindings.headNode == null) {
    bindings.headNode = node;
    bindings.tailNode = node;
  } else if (bindings.currentNode == null) {
    bindings.tailNode!.next = node;
    bindings.tailNode = node;
  } else if (bindings.currentNode != null) {
    final next = bindings.currentNode!.next;
    if (next != null) {
      warn(
        'Do not use hooks like useSignal inside conditional statements. '
        'This will cause a reset of subsequent calls and may lead to unexpected behavior.',
      );
    }

    bindings.currentNode!.next = node;
    bindings.currentNode = node;
    bindings.tailNode = node;
  }
}
