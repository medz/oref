import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

class Simple extends StatelessWidget {
  const Simple({super.key});

  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);
    void increment() => count(count() + 1);

    return Column(
      children: [
        // Only rebuild the `Text` widget when count changes

        // First way
        SignalBuilder(builder: (_) => Text('Count: ${count()}')),

        // Second way
        Builder(builder: (context) => Text('Count: ${watch(context, count)}')),

        // Third way
        Builder(
          builder: (context) {
            final effect = useWidgetEffect(context);
            return effect.using(() => Text("Count: ${count()}"));
          },
        ),

        TextButton(onPressed: increment, child: const Text('Increment')),
      ],
    );
  }
}
