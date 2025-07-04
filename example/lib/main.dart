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
      home: const HomeScrren(),
    );
  }
}

class HomeScrren extends StatelessWidget {
  const HomeScrren({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Home: Post-frame callback executed');
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Oref Example")),
      body: const OrefTestWidget(),
    );
  }
}

class OrefTestWidget extends StatelessWidget {
  const OrefTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(context, 0);

    void increment() => count(count + 1);

    return Center(
      child: Column(
        children: [
          Text("Count: ${count()}"),
          FilledButton(onPressed: increment, child: const Text('Increment')),
        ],
      ),
    );
  }
}
