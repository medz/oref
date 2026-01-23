import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset.dart" as alien;
import "package:flutter/widgets.dart";

import "context.dart";
import "memoized.dart";
import "watch.dart";
import "../devtools/devtools.dart";
import "_element_disposer.dart";

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
alien.WritableSignal<T> signal<T>(
  BuildContext? context,
  T initialValue, {
  String? debugLabel,
  Object? debugOwner,
  String? debugScope,
  String? debugNote,
}) {
  if (context == null) {
    final signal = _SignalImpl(initialValue);
    registerSignal(
      signal,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugNote: debugNote,
    );
    return signal;
  }

  final signal = useMemoized(context, () => _SignalImpl(initialValue));
  final registered = registerSignal(
    signal,
    context: context,
    debugLabel: debugLabel,
    debugOwner: debugOwner,
    debugScope: debugScope,
    debugNote: debugNote,
  );
  if (registered) {
    registerElementDisposer(context, () => markSignalDisposed(signal));
  }
  return signal;
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
  void set(T newValue) {
    recordSignalWrite(this, newValue);
    super.set(newValue);
  }

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
