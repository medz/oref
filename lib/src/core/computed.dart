import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset.dart" as alien;
import "package:flutter/widgets.dart";

import "context.dart";
import "memoized.dart";
import "watch.dart";

alien.Computed<T> computed<T>(
  BuildContext? context,
  T Function(T? previousValue) getter,
) {
  if (context == null) {
    return _OrefComputed<T>(getter);
  }

  final c = useMemoized(context, () => _OrefComputed<T>(getter));
  assert(() {
    c.fn = getter;
    c.flags &= 16 /* Dirty */;
    return true;
  }());

  return c;
}

class _OrefComputed<T> extends alien.ComputedNode<T>
    implements alien.Computed<T> {
  _OrefComputed(this.fn) : super(flags: .none, getter: fn);

  T Function(T?) fn;

  @override
  T Function(T?) get getter => fn;

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
///   set: (value) => count.set(math.sqrt(value)),
/// );
///
/// count.set(2);
/// print(count()); // Print 2.0
/// print(squared()); // Print 4.0
///
/// squared.set(16);
/// print(count()); // Print 4.0
/// print(squared()); // Print 16.0
/// ```
/// {@endtemplate}
abstract interface class WritableComputed<T>
    implements alien.Computed<T>, alien.WritableSignal<T> {}

/// {@macro oref.core.writable-computed}
WritableComputed<T> writableComputed<T>(
  BuildContext? context, {
  required T Function(T? cached) get,
  required void Function(T value) set,
}) {
  if (context == null) return _OrefWritableComputed(get, set);

  final c = useMemoized(context, () => _OrefWritableComputed(get, set));
  assert(() {
    c.fn = get;
    c.setter = set;
    c.flags &= 16;
    return true;
  }());

  return c;
}

class _OrefWritableComputed<T> extends _OrefComputed<T>
    implements WritableComputed<T> {
  _OrefWritableComputed(super.fn, this.setter);

  void Function(T value) setter;

  @override
  void set(T value) => setter(value);
}
