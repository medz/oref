import 'package:flutter/material.dart';
import 'package:oref/oref.dart';
import 'package:alien_signals/alien_signals.dart'
    show getCurrentScope, getCurrentSub;

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oref Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Counter(),
    );
  }
}

class Counter extends StatelessWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);
    void increment() => count(count() + 1);

    final scope = getWidgetScope(context);
    effect(context, () {
      if (count() > 5) {
        scope.stop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(child: Text("Count: ${count()}")),
      floatingActionButton: FloatingActionButton(
        onPressed: increment,
        child: const Icon(Icons.plus_one),
      ),
    );
  }
}
