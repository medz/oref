import 'package:alien_signals/alien_signals.dart' as alien;

/// Global signal utilities.
base class GlobalSignals {
  const GlobalSignals._();

  /// {@macro oref.signal}
  ///
  /// Example:
  /// ```dart
  /// final count = GlobalSignals.create(0);
  /// ```
  static const create = alien.signal;

  /// {@macro oref.computed}
  ///
  /// Example:
  /// ```dart
  /// final count = GlobalSignals.create(0);
  /// final double = GlobalSignals.computed(() => count() * 2);
  /// ```
  static const computed = alien.computed;

  /// {@macro oref.effect}
  ///
  /// Example:
  /// ```dart
  /// final count = GlobalSignals.create(0);
  /// GlobalSignals.effect(() {
  ///   print('Count changed: ${count()}');
  /// });
  ///
  /// count(1);
  /// ```
  static const effect = alien.effect;

  /// {@macro oref.effect-scope}
  static const effectScope = alien.effectScope;
}
