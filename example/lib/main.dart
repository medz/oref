import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

import 'async_data.dart';
import 'hashcode.dart';
import 'permanent_counter.dart';
import 'simple.dart';
import 'todo.dart';

void main() {
  runApp(const ExampleApp());
}

final routes = <String, WidgetBuilder>{
  "todo": (_) => const TodoApp(),
  "permanent-counter": (_) => const PermanentCounter(),
  "simple": (_) => const Simple(),
  'hashcode': (_) => const HashCode(),
  'async-data': (_) => const AsyncDataExample(),
};

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
      routes: routes,
    );
  }
}

class Counter extends StatelessWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);
    void increment() => count.set(count() + 1);

    debugPrint("Counter build"); // Only print once.

    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: ListView(
        children: [
          Center(
            // Only rebuild when count changes
            child: SignalBuilder(builder: (_) => Text("Count: ${count()}")),
          ),
          const SizedBox(height: 16),

          ...ListTile.divideTiles(
            context: context,
            tiles: routes.keys.map(
              (name) => ListTile(
                title: Text(name),
                onTap: () => Navigator.of(context).pushNamed(name),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: increment,
        child: const Icon(Icons.plus_one),
      ),
    );
  }
}
