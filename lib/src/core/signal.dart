import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset_developer.dart" as alien;
import "package:flutter/widgets.dart";

import "context.dart";
import "memoized.dart";
import "watch.dart";

export 'package:alien_signals/alien_signals.dart'
    show SignalDotValueGetter, WritableSignalDotValueGetterSetter;

typedef Signal<T> = alien.Signal<T>;
typedef WritableSignal<T> = alien.WritableSignal<T>;

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
    return _OrefSignal(initialValue: initialValue);
  }

  return useMemoized(
    context,
    () => _OrefSignal(initialValue: initialValue, context: context),
  );
}

class _OrefSignal<T> extends alien.PresetWritableSignal<T> {
  _OrefSignal({required super.initialValue, this.context})
    : super(flags: 1 /* Mutable */);

  final BuildContext? context;

  @override
  T call([T? newValue, nulls = false]) {
    if (newValue != null || (null is T && nulls)) {
      return super(newValue, nulls);
    }

    if (alien.getActiveSub() == null) {
      if (getActiveContext() case final Element element) {
        return watch(element, super.call);
      }
    }

    return super(newValue, nulls);
  }
}
