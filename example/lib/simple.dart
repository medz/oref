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
        Text('Count: ${count()}'),
        TextButton(onPressed: increment, child: const Text('Increment')),
      ],
    );
  }
}
