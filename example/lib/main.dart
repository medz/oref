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
    final count = useSignal(context, 0);
    final doubleCount = useComputed(context, (_) => count * 2);

    void increment() => count(count() + 1);

    useEffect(context, () {
      debugPrint('useEffect 1, count: ${count()}');
    });

    useEffect(context, () {
      debugPrint('useEffect 2, count: ${doubleCount()}');
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Oref Example")),
      body: Center(
        child: Text("Count: ${count()}", style: TextStyle(fontSize: 36)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: increment,
        child: const Icon(Icons.plus_one),
      ),
    );
  }
}
