import 'dart:math' as math;

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
      title: 'Oref Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oref Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: 'Counter + computed + writableComputed',
            child: CounterSection(),
          ),
          SizedBox(height: 16),
          _Section(
            title: 'Effect + batch',
            child: EffectBatchSection(),
          ),
          SizedBox(height: 16),
          _Section(
            title: 'untrack()',
            child: UntrackSection(),
          ),
          SizedBox(height: 16),
          _Section(
            title: 'useAsyncData',
            child: AsyncDataSection(),
          ),
          SizedBox(height: 16),
          _Section(
            title: 'Walkthrough: searchable list',
            child: WalkthroughSection(),
          ),
          SizedBox(height: 16),
          _Section(
            title: 'Walkthrough: checkout total + autosave',
            child: CheckoutWorkflowSection(),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class CounterSection extends StatelessWidget {
  const CounterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final count = signal<double>(context, 2);
    final doubled = computed<double>(context, (_) => count() * 2);
    final squared = writableComputed<double>(
      context,
      get: (_) => count() * count(),
      set: (value) {
        final safe = value < 0 ? 0.0 : value;
        count.set(math.sqrt(safe));
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('count: ${count().toStringAsFixed(1)}'),
        Text('doubled (computed): ${doubled().toStringAsFixed(1)}'),
        Text('squared (writable): ${squared().toStringAsFixed(1)}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => count.set(count() + 1),
              child: const Text('Increment'),
            ),
            OutlinedButton(
              onPressed: () => squared.set(81),
              child: const Text('Set squared = 81'),
            ),
          ],
        ),
      ],
    );
  }
}

class EffectBatchSection extends StatelessWidget {
  const EffectBatchSection({super.key});

  @override
  Widget build(BuildContext context) {
    final a = signal<int>(context, 1);
    final b = signal<int>(context, 2);
    final sum = computed<int>(context, (_) => a() + b());
    final effectRuns = signal<int>(context, 0);

    effect(context, () {
      sum();
      final current = untrack(() => effectRuns());
      effectRuns.set(current + 1);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('a: ${a()}  b: ${b()}  sum (computed): ${sum()}'),
        Text('effect runs: ${effectRuns()}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => a.set(a() + 1),
              child: const Text('Increment A'),
            ),
            ElevatedButton(
              onPressed: () => b.set(b() + 1),
              child: const Text('Increment B'),
            ),
            OutlinedButton(
              onPressed: () {
                batch(() {
                  a.set(a() + 1);
                  b.set(b() + 1);
                });
              },
              child: const Text('Batch +1 both'),
            ),
          ],
        ),
      ],
    );
  }
}

class UntrackSection extends StatelessWidget {
  const UntrackSection({super.key});

  @override
  Widget build(BuildContext context) {
    final source = signal<int>(context, 1);
    final noise = signal<int>(context, 100);
    final tracked = computed<int>(context, (_) => source() + noise());
    final untracked =
        computed<int>(context, (_) => source() + untrack(() => noise()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SignalBuilder(
          builder: (context) =>
              Text('source: ${source()}  noise: ${noise()}'),
        ),
        SignalBuilder(builder: (context) => Text('tracked: ${tracked()}')),
        SignalBuilder(builder: (context) => Text('untracked: ${untracked()}')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => source.set(source() + 1),
              child: const Text('Bump source'),
            ),
            OutlinedButton(
              onPressed: () => noise.set(noise() + 10),
              child: const Text('Bump noise'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Note: untracked ignores noise changes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class AsyncDataSection extends StatelessWidget {
  const AsyncDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final requestId = signal<int>(context, 1);
    final result = useAsyncData<String>(
      context,
      () async {
        final id = requestId();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return 'Result #$id';
      },
      defaults: () => 'Idle',
    );

    final status = result.when(
      context: context,
      idle: (data) => 'Idle: ${data ?? '-'}',
      pending: (data) => 'Loading... ${data ?? ''}',
      success: (data) => 'Success: ${data ?? '-'}',
      error: (error) => 'Error: ${error?.error ?? 'unknown'}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('request id: ${requestId()}'),
        Text(status),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => requestId.set(requestId() + 1),
              child: const Text('Next request'),
            ),
            OutlinedButton(
              onPressed: () async {
                await result.refresh();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      ],
    );
  }
}

class WalkthroughSection extends StatelessWidget {
  const WalkthroughSection({super.key});

  @override
  Widget build(BuildContext context) {
    final query = signal<String>(context, '');
    final items = ReactiveList.scoped(context, [
      'Aurora',
      'Comet',
      'Nebula',
      'Orion',
      'Pulsar',
    ]);
    final nextId = signal<int>(context, 1);
    final controller = useMemoized(context, () => TextEditingController());

    effect(context, () {
      onEffectDispose(controller.dispose);
    });

    final filtered = computed<List<String>>(context, (_) {
      final q = query().trim().toLowerCase();
      if (q.isEmpty) return List.unmodifiable(items);
      return items.where((item) => item.toLowerCase().contains(q)).toList();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('walkthrough-query'),
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Search',
            suffixIcon: IconButton(
              tooltip: 'Clear filter',
              onPressed: () {
                controller.clear();
                query.set('');
              },
              icon: const Icon(Icons.clear),
            ),
          ),
          onChanged: query.set,
        ),
        const SizedBox(height: 8),
        SignalBuilder(
          builder: (context) {
            final results = filtered();
            final total = items.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        items.add('Nova ${nextId()}');
                        nextId.set(nextId() + 1);
                      },
                      child: const Text('Add item'),
                    ),
                    OutlinedButton(
                      onPressed: total == 0 ? null : () => items.removeLast(),
                      child: const Text('Remove last'),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.clear();
                        query.set('');
                      },
                      child: const Text('Clear filter'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('showing ${results.length} of $total'),
                const SizedBox(height: 4),
                for (final item in results) Text(item),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CheckoutWorkflowSection extends StatelessWidget {
  const CheckoutWorkflowSection({super.key});

  @override
  Widget build(BuildContext context) {
    final qty = signal<int>(context, 1);
    final unitPrice = signal<double>(context, 19.0);
    final discount = signal<double>(context, 0.0);
    final saves = signal<int>(context, 0);

    final subtotal = computed<double>(context, (_) => qty() * unitPrice());
    final total = computed<double>(
      context,
      (_) => subtotal() * (1 - discount()),
    );

    effect(context, () {
      total();
      final current = untrack(() => saves());
      saves.set(current + 1);
    });

    String money(double value) => value.toStringAsFixed(2);
    String percent(double value) => '${(value * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('qty: ${qty()}'),
        Text('unit: \$${money(unitPrice())}'),
        Text('subtotal: \$${money(subtotal())}'),
        Text('discount: ${percent(discount())}'),
        Text('total: \$${money(total())}'),
        Text('autosave runs: ${saves()}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => qty.set(qty() + 1),
              child: const Text('Add 1 item'),
            ),
            OutlinedButton(
              onPressed: qty() <= 1 ? null : () => qty.set(qty() - 1),
              child: const Text('Remove 1 item'),
            ),
            TextButton(
              onPressed: () =>
                  discount.set(discount() == 0 ? 0.1 : 0.0),
              child: const Text('Toggle 10% promo'),
            ),
            TextButton(
              onPressed: () => unitPrice.set(24.0),
              child: const Text('Set price = 24'),
            ),
          ],
        ),
      ],
    );
  }
}
