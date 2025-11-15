import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

int parentBuildCount = 0;

class HashCode extends StatelessWidget {
  const HashCode({super.key});

  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);

    parentBuildCount++;

    return Scaffold(
      body: Column(
        children: [
          Text('$parentBuildCount'),
          SignalBuilder(builder: (_) => TextContextTest(index: count())),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.set(count() + 1),
        child: const Icon(Icons.add),
      ),
    );
  }
}

int memoryFrequencyBuildCount = 0;

class TextContextTest extends StatelessWidget {
  const TextContextTest({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final count = useMemoized(context, () {
      memoryFrequencyBuildCount++;
      return memoryFrequencyBuildCount;
    });

    return Text(
      "$index, hashcode: ${context.hashCode}, Memory Frequency: $count",
    );
  }
}
