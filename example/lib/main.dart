import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

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
