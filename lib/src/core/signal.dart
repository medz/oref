import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset.dart" as alien;
import "package:flutter/widgets.dart";

import "context.dart";
import "memoized.dart";
import "watch.dart";

/// Creates a reactive signal with an initial value.
///
/// A signal is a reactive value container that notifies dependents when its
/// value changes. The returned signal can be used to:
/// - Get the current value by calling it with no arguments
/// - Set a new value via the `.set(value)` method
///
/// Example:
/// ```dart
/// final count = signal(context, 0);
/// count(); // get value
/// count.set(1); // set value
/// ```
alien.WritableSignal<T> signal<T>(BuildContext? context, T initialValue) {
  if (context == null) {
    return _SignalImpl(initialValue);
  }

  return useMemoized(context, () => _SignalImpl(initialValue));
}

class _SignalImpl<T> extends alien.SignalNode<T>
    implements alien.WritableSignal<T> {
  _SignalImpl(T initialValue)
    : super(
        flags: .mutable,
        pendingValue: initialValue,
        currentValue: initialValue,
      );

  @override
  T call() {
    if (alien.getActiveSub() == null) {
      if (getActiveContext() case final Element element) {
        return watch(element, get);
      }
    }

    return get();
  }
}
