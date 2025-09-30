import 'package:flutter/widgets.dart';

import 'watch.dart';

/// {@template oref.core.signal_builder}
/// A [SignalBuilder] is a widget that builds a widget tree based on a signal/computed.
///
/// Example:
/// ```dart
/// final first = signal(context, "Seven");
/// final last = signal(context, "Du");
///
/// SignalBuilder(builder: (context) {
///   return Text('${first()} ${last()}');
/// });
/// ```
///
/// ### Why need this Widget?
///
/// The default collection scope for signals is the current widget. This means that by default,
/// any update to a signal value within the current widget's scope triggers a widget rebuild.
///
/// **[SignalBuilder] helps narrow the signal rebuild scope, updating only the widgets that must be rebuilt.**
/// {@endtemplate}
class SignalBuilder extends StatelessWidget {
  /// {@macro oref.core.signal_builder}
  const SignalBuilder({super.key, required this.builder});

  /// A widget builder, automatically rebuild when signals value changes.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => watch(context, () => builder(context));
}
