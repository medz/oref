import 'package:flutter/widgets.dart';

import '../core/computed.dart';
import '../core/signal_build_context.dart';

class SignalBuilder<T> extends StatelessWidget {
  const SignalBuilder({super.key, required this.getter, required this.builder});

  final T Function() getter;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    final value = computed<T>(context, (_) => getter());
    return Builder(
      builder: (context) => builder(context, context.watch(value)),
    );
  }
}
