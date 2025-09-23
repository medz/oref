import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

class Counter extends StatelessWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);
    void increment() => count(count() + 1);

    return Column(
      children: [
        // Only rebuild when count changes
        SignalBuilder(builder: (_) => Text("Count: ${count()}")),
        TextButton(onPressed: increment, child: const Text('Increment')),
      ],
    );
  }
}
