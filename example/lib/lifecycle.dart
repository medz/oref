import 'package:flutter/material.dart';
import 'package:oref/experimental/lifecycle.dart';
import 'package:oref/oref.dart';

class LifecycleExample extends StatelessWidget {
  const LifecycleExample({super.key});

  @override
  Widget build(BuildContext context) {
    final key = signal(context, UniqueKey());

    return Scaffold(
      appBar: AppBar(title: const Text('Lifecycle Example')),
      body: _Example(key: key()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => key(UniqueKey()),
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
      mounted(true);
    });

    onUpdated(context, () {
      updateTick(updateTick() + 1);
    });

    // Not yet implemented
    // onUnmounted(context, () {
    //   debugPrint('Unmounted');
    // });

    return Scaffold(
      body: Column(
        spacing: 12,
        children: [
          SignalBuilder(builder: (context) => Text('Trigger: ${trigger()}')),
          SignalBuilder(builder: (context) => Text('Mounted: ${mounted()}')),
          SignalBuilder(
            builder: (context) => Text('Update Tick: ${updateTick()}'),
          ),
          FilledButton(
            onPressed: () => trigger(trigger() + 1),
            child: const Text('Trigger'),
          ),
        ],
      ),
    );
  }
}
