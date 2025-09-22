import 'package:flutter/widgets.dart';

import '../core/computed.dart';
import '../utils/signal_build_context.dart';

/// {@template oref.signal-builder}
/// A [SignalBuilder] is a widget that builds a widget tree based on a signal/computed value.
///
/// Example:
/// ```dart
/// SignalBuilder<int>(
///   getter: count,
///   builder: (context, value) => Text('$value'),
/// );
/// ```
///
/// ### Why need this Widget?
///
/// The default collection scope for signals is the current widget. This means that by default,
/// any update to a signal value within the current widget's scope triggers a widget rebuild.
///
/// **[SignalBuilder] helps narrow the signal rebuild scope, updating only the widgets that must be rebuilt.**
/// {@endtemplate}
class SignalBuilder<T> extends StatelessWidget {
  /// {@macro oref.signal-builder}
  const SignalBuilder({super.key, required this.getter, required this.builder});

  /// A function that returns the value of the signal.
  final T Function() getter;

  /// A function that builds the widget tree based on the signal value.
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    final value = computed<T>(context, (_) => getter());
    return Builder(
      builder: (context) => builder(context, context.watch(value)),
    );
  }
}
