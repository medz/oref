import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset_developer.dart" as alien;
import "package:flutter/widgets.dart";

import "context.dart";
import "memoized.dart";
import "watch.dart";

typedef Computed<T> = alien.Computed<T>;

Computed<T> computed<T>(
  BuildContext? context,
  T Function(T? previousValue) getter,
) {
  if (context == null) {
    return _OrefComputed<T>(getter: getter);
  }

  return useMemoized(context, () => _OrefComputed<T>(getter: getter));
}

class _OrefComputed<T> extends alien.PresetComputed<T> {
  _OrefComputed({required super.getter}) : super(flags: 0 /* None */);

  @override
  T call() {
    if (alien.getActiveSub() == null) {
      if (getActiveContext() case final Element element) {
        return watch(element, super.call);
      }
    }

    return super();
  }
}

//------------------------- Writable Computed ---------------------------//

/// {@template oref.core.writable-computed}
/// Factory method for creating a writable computed signal.
///
/// Example:
/// ```dart
/// import 'dart:math' as math;
///
/// final count = signal<double>(null, 0);
/// final squared = writableComputed<double>(null,
///   get: (_) => count() * count(),
///   set: (value) => count(math.sqrt(value)),
/// );
///
/// count(2);
/// print(count()); // Print 2.0
/// print(squared()); // Print 4.0
///
/// squared(16);
/// print(count()); // Print 4.0
/// print(squared()); // Print 16.0
/// ```
/// {@endtemplate}
abstract interface class WritableComputed<T>
    implements Computed<T>, alien.WritableSignal<T> {}

/// {@macro oref.core.writable-computed}
WritableComputed<T> writableComputed<T>(
  BuildContext? context, {
  required T Function(T? cached) get,
  required void Function(T value) set,
}) {
  if (context == null) {
    return _OrefWritableComputed(getter: get, setter: set);
  }

  return useMemoized(
    context,
    () => _OrefWritableComputed(getter: get, setter: set),
  );
}

class _OrefWritableComputed<T> extends _OrefComputed<T>
    implements WritableComputed<T> {
  _OrefWritableComputed({required super.getter, required this.setter});

  final void Function(T value) setter;

  @override
  T call([T? value, bool nulls = false]) {
    if (value != null || (null is T && nulls)) {
      setter(value as T);
      return value;
    }

    return super.call();
  }
}
