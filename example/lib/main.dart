import 'package:flutter/material.dart';
import 'package:oref/oref.dart';
// import 'package:oref/oref.dart';

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
      body: const OrefWidget(),
    );
  }
}

class OrefWidget extends StatelessWidget {
  const OrefWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(context, 0);

    void increment() => count(count() + 1);

    debugPrint("Print In build - Count: ${count()}");
    useEffect(context, () {
      debugPrint("Print in Effect - Count: ${count()}");
    });

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

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return MainState();
  }
}

class MainState extends State<MainWidget> {
  int count = 0;

  void increment() {
    setState(() => count++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TestWidget(count: count),
        FilledButton(onPressed: increment, child: const Text('Increment')),
      ],
    );
  }
}

class TestWidget extends StatelessWidget {
  const TestWidget({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    useEffectScope(context, () {
      debugPrint('TestWidget: useEffectScope 1');
    });
    useEffectScope(context, () {
      debugPrint('TestWidget: useEffectScope 2');
    });

    return Text("Count: $count");
  }
}
