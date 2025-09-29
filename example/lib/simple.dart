import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

class Simple extends StatelessWidget {
  const Simple({super.key});

  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);
    void increment() => count.value++;

    return Column(
      children: [
        // First way
        SignalBuilder(builder: (_) => Text('Count: ${count.value}')),

        // Second way
        Builder(
          builder: (context) =>
              Text('Count: ${watch(context, () => count.value)}'),
        ),

        TextButton(onPressed: increment, child: const Text('Increment')),
      ],
    );
  }
}
