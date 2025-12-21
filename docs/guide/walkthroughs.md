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
