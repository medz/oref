# Walkthroughs

## Searchable List

This example combines a query signal, a reactive list, and a computed filter.

```dart
final query = signal(context, '');
final items = ReactiveList.scoped(context, [
  'Aurora',
  'Comet',
  'Nebula',
  'Orion',
  'Pulsar',
]);

final filtered = computed<List<String>>(context, (_) {
  final q = query().trim().toLowerCase();
  if (q.isEmpty) return List.unmodifiable(items);
  return items.where((item) => item.toLowerCase().contains(q)).toList();
});
```

UI wiring:

```dart
TextField(
  decoration: const InputDecoration(labelText: 'Search'),
  onChanged: query.set,
);

SignalBuilder(
  builder: (context) {
    final results = filtered();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Showing ${results.length} items'),
        for (final item in results) Text(item),
      ],
    );
  },
);
```

Try it in the example app and watch the list update instantly.

## Checkout Total + Autosave

This workflow shows `.set(...)`, `computed`, and `effect` working together.

```dart
final qty = signal(context, 1);
final unitPrice = signal(context, 19.0);
final discount = signal(context, 0.0); // 0%..30%

final subtotal = computed<double>(context, (_) => qty() * unitPrice());
final total = computed<double>(context, (_) => subtotal() * (1 - discount()));

final saves = signal(context, 0);
effect(context, () {
  total(); // track computed
  final current = untrack(() => saves());
  saves.set(current + 1); // autosave counter
});
```

Update inputs using `.set(...)`:

```dart
qty.set(qty() + 1);
discount.set(0.1); // 10% promo
unitPrice.set(24.0);
```

## Flutter Examples (from the example app)

::: code-group

<<< ../../example/lib/main.dart#walkthrough-section [Walkthrough: searchable list]

<<< ../../example/lib/main.dart#checkout-workflow-section [Walkthrough: checkout total + autosave]

:::
