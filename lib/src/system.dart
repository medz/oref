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

class BindingNode<T> {
  BindingNode({required this.value, this.next});

  final T value;
  BindingNode? next;
}

class BindingState {
  BindingNode? head;

  /// Tail pointer for O(1) append operations instead of O(n) traversal
  BindingNode? tail;
  BindingNode? current;
  bool isRendering = false;
}

BuildContext? activeContext;
bool shouldTriggerContextEffect = true;
bool withoutContext = false;

final contextEffect = Expando<Effect>("oref context effect");
final bindings = Expando<BindingState>("oref bindings");

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

/// Finds an existing binding at the current position or returns null.
/// Also handles render cycle initialization and moves the current pointer.
T? _findBinding<T>(BuildContext context) {
  if (withoutContext) return null;

  // Initialize binding state if needed
  final bindingState = bindings[context] ??= BindingState();

  // Check if we need to start a new render cycle
  if (!bindingState.isRendering) {
    bindingState.isRendering = true;
    bindingState.current = bindingState.head;
    // Schedule reset for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bindingState.current = null;
      bindingState.isRendering = false;
    });
  }

  // Try to use existing binding at current position
  final currentNode = bindingState.current;

  if (currentNode != null && currentNode.value is T) {
    // Move to next position for subsequent binding calls
    bindingState.current = currentNode.next;
    return currentNode.value as T;
  }

  return null;
}

/// Stores a new binding value at the current position in the binding chain.
/// Must be called after _findBinding when a new binding needs to be created.
void _storeBinding<T>(BuildContext context, T value) {
  if (withoutContext) return;

  final bindingState = bindings[context]!;
  final currentNode = bindingState.current;

  // Create new binding node
  final newNode = BindingNode<T>(value: value);

  if (bindingState.head == null) {
    // This is the very first binding
    bindingState.head = newNode;
    bindingState.tail = newNode;
  } else if (currentNode == null) {
    // We're past the end of the existing bindings, append new one
    bindingState.tail!.next = newNode;
    bindingState.tail = newNode;
  }
}

/// Creates a signal that can be used within a Flutter widget.
///
/// The signal will automatically trigger rebuilds when its value changes,
/// but only if the widget is not already marked as dirty.
T Function([T? value, bool nulls]) useSignal<T>(
  BuildContext context,
  T initialValue,
) {
  // Try to find existing binding
  final existing = _findBinding<Signal<T>>(context);
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

  // Store the new binding
  _storeBinding(context, instance);
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
  // Try to find existing binding
  final existing = _findBinding<Computed<T>>(context);
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
  _storeBinding(context, instance);
  return instance.oper;
}

/// Creates an effect that runs whenever its dependencies change.
///
/// Returns a dispose function that should be called to stop the effect.
VoidCallback useEffect(BuildContext context, VoidCallback callback) {
  // Try to find existing binding
  final existing = _findBinding<Effect>(context);
  if (existing != null) return existing.stop;

  // Create new effect
  final prevContext = setCurrentContext(context);
  try {
    final effect = createEffect(context, callback);
    _storeBinding(context, effect);
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
  // Try to find existing binding
  final existing = _findBinding<EffectScope>(context);
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
    _storeBinding(context, scope);
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
