import '../core/signal.dart' as core;
import '../core/computed.dart' as core;
import '../core/effect.dart' as core;
import '../core/effect_scope.dart' as core;

T _infer<T>(T input) => input;

/// Global signal utilities.
@Deprecated('Use `alien` directly')
base class GlobalSignals {
  const GlobalSignals._();

  /// {@macro oref.signal}
  ///
  /// Example:
  /// ```dart
  /// final count = signal(null, 0);
  /// ```
  @Deprecated('Remove in 2.1 version, Use `signal` instead')
  static final create = _infer(
    <T>(T initialValue) => core.signal(null, initialValue),
  );

  /// {@macro oref.computed}
  ///
  /// Example:
  /// ```dart
  /// final count = signal(null, 0);
  /// final double = computed((_) => count() * 2);
  /// ```
  @Deprecated('Remove in 2.1 version, Use `computed` instead')
  static final computed = _infer(
    <T>(T Function(T?) getter) => core.computed(null, getter),
  );

  /// {@macro oref.effect}
  ///
  /// Example:
  /// ```dart
  /// final count = signal(null, 0);
  /// effect(() {
  ///   print('Count changed: ${count()}');
  /// });
  ///
  /// count(1);
  /// ```
  @Deprecated('Remove in 2.1 version, Use `effect` instead')
  static final effect = _infer((void Function() run) => core.effect(null, run));

  /// {@macro oref.effect-scope}
  @Deprecated('Remove in 2.1 version, Use `effectScope` instead')
  static final effectScope = _infer(
    (void Function() run) => core.effectScope(null, run),
  );
}
