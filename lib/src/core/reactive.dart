import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

final class _Wrap<T> {
  const _Wrap(this.value);
  final T value;
}

/// Reactive mixin class that provides a signal-based reactive system.
///
/// The [Reactive] allows you to implement your own reactive types.
///
/// Example:
/// ```dart
/// class Counter with Reactive<Counter> {
///   int untrackedValue = 0;
///
///   int get value {
///     track();
///     return untrackedValue;
///   }
///
///   void increment() {
///     untrackedValue++;
///     trigger();
///   }
/// }
///
/// class CounterWidget extends StatelessWidget {
///   const CounterWidget({Key? key});
///
///   @override
///   Widget build(BuildContext context) {
///     final counter = useMemoized(context, Counter.new);
///
///     return Column(
///       children: [
///         Text('${counter.value}'),
///         TextButton(
///           onPressed: counter.increment,
///           child: const Text('Increment'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// Reference:
/// - [ReactiveList] - A reactive list implementation.
/// - [ReactiveMap] - A reactive map implementation.
/// - [ReactiveSet] - A reactive set implementation.
abstract mixin class Reactive<T extends Reactive<T>> {
  late final _signal = alien.signal(_Wrap(this as T));

  /// Tracks the current reactive state.
  @protected
  void track() => _signal();

  /// Triggers a change in the reactive state.
  void trigger() => _signal(_Wrap(this as T));

  /// Returns reactive itself.
  T call() => _signal().value;
}
