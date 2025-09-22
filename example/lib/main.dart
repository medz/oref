import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

import 'todo.dart';

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
      initialRoute: "counter",
      routes: {
        "counter": (_) => const Counter(),
        "todo": (_) => const TodoApp(),
      },
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
      body: ListView(
        children: [
          Center(
            // Only rebuild when count changes
            child: SignalBuilder(
              getter: count,
              builder: (_, count) => Text("Count: $count"),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Todo App'),
            subtitle: const Text('Manage your tasks'),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => Navigator.of(context).pushNamed('todo'),
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
