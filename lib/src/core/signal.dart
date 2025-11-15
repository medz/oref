import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset.dart" as alien;
import "package:flutter/widgets.dart";

import "context.dart";
import "memoized.dart";
import "watch.dart";

/// Creates a reactive signal with an initial value.
///
/// A signal is a reactive value container that notifies dependents when its
/// value changes. The returned function can be used to:
/// - Get the current value when called with no arguments
/// - Set a new value when called with a value argument
/// - Control whether null values should be treated as updates when [nulls] is true
///
/// Example:
/// ```dart
/// final count = signal(context, 0);
/// count(); // get value
/// count(1); // set value
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
