import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

class LifecycleExample extends StatelessWidget {
  const LifecycleExample({super.key});

  @override
  Widget build(BuildContext context) {
    final key = signal(context, UniqueKey());

    return Scaffold(
      appBar: AppBar(title: const Text('Lifecycle Example')),
      body: _Example(key: key.value),
      floatingActionButton: FloatingActionButton(
        onPressed: () => key.value = UniqueKey(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _Example extends StatelessWidget {
  const _Example({super.key});

  @override
  Widget build(BuildContext context) {
    final trigger = signal(context, 0);

    final mounted = signal(context, false);
    final updateTick = signal(context, 0);

    onMounted(context, () {
      mounted.value = true;
    });

    onUpdated(context, () {
      updateTick.value += 1;
    });

    onUnmounted(context, () {
      debugPrint('Unmounted');
    });

    return Scaffold(
      body: Column(
        spacing: 12,
        children: [
          SignalBuilder(
            builder: (context) => Text('Trigger: ${trigger.value}'),
          ),
          SignalBuilder(
            builder: (context) => Text('Mounted: ${mounted.value}'),
          ),
          SignalBuilder(
            builder: (context) => Text('Update Tick: ${updateTick.value}'),
          ),
          FilledButton(
            onPressed: () => trigger.value += 1,
            child: const Text('Trigger'),
          ),
        ],
      ),
    );
  }
}
