import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

import 'permanent_counter.dart';
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
        "permanent-counter": (_) => const PermanentCounter(),
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
          ListTile(
            title: const Text('Todo App'),
            subtitle: const Text('Manage your tasks'),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => Navigator.of(context).pushNamed('todo'),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Permanent Counter'),
            subtitle: const Text('Store count across sessions'),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  Navigator.of(context).pushNamed('permanent-counter'),
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
