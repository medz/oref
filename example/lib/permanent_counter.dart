import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oref/oref.dart';
import 'package:shared_preferences/shared_preferences.dart';

T infer<T extends Function>(T func) => func;
T inferReturnType<T>(T Function() factory) => factory();

final usePrefs = inferReturnType(() {
  final prefs = GlobalSignals.create<SharedPreferences?>(null);

  unawaited(
    Future.microtask(() async {
      prefs(await SharedPreferences.getInstance());
    }),
  );

  return prefs;
});

final usePermanentCounter = infer((BuildContext context, String name) {
  final count = signal(context, 0);

  void increment() => count(count() + 1);
  void decrement() => count(count() - 1);

  bool firstRun = false;
  effect(context, () {
    final prefs = usePrefs();
    if (prefs == null) return;

    final value = count();
    if (!firstRun) {
      count(prefs.getInt(name) ?? 0);
      firstRun = true;
      return;
    }

    unawaited(prefs.setInt(name, value));
  });

  return (value: count, increment: increment, decrement: decrement);
});

class PermanentCounter extends StatelessWidget {
  const PermanentCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = usePermanentCounter(context, "my-counter");

    return Scaffold(
      appBar: AppBar(title: Text('Permanent Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            SignalBuilder(
              getter: counter.value,
              builder: (_, value) => Text('Count: $value'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                IconButton(
                  onPressed: counter.decrement,
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: counter.increment,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
