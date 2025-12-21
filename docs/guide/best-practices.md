# Best Practices

## Scope Reactivity

Create signals inside widget builds to bind them to the widget lifecycle:

```dart
final count = signal(context, 0);
```

If you create signals outside widgets, pass `null` and clean up effects manually.

## Keep Derived Logic in Computed

Use `computed` for derived state instead of duplicating logic in widgets:

```dart
final total = computed(context, (_) => items.length);
```

Avoid writing inside computed getters.

## Limit Rebuilds with SignalBuilder

Wrap only the UI that needs to update:

```dart
SignalBuilder(
  builder: (context) => Text('Count: ${count()}'),
);
```

Use `SignalBuilder` when:
- Only a small subtree depends on a signal/computed.
- You want to avoid rebuilding a large widget tree.
- You’re reading signals inside a list item or tile.

## Batch Multi-step Updates

Group updates to reduce recomputation:

```dart
batch(() {
  a.set(a() + 1);
  b.set(b() + 1);
});
```

Use `batch` when:
- You update multiple signals in one user action.
- You update a collection with many mutations (e.g. sort, clear + addAll).
- You want effects/computed to re-run only once for the batch.

## Use Reactive Collections for In-place Mutations

Prefer `ReactiveList/Map/Set` when mutating collections:

```dart
final todos = ReactiveList.scoped(context, ['A', 'B']);
todos.add('C');
```

## Track What You Mean

Inside effects, use `untrack` to avoid accidental dependencies:

```dart
effect(context, () {
  final snapshot = untrack(() => expensive());
  debugPrint('snapshot: $snapshot');
});
```

## Flutter Examples (from the example app)

::: code-group

<<< ../../example/lib/main.dart#counter-section [Counter + computed + writableComputed]

<<< ../../example/lib/main.dart#effect-batch-section [Effect + batch]

<<< ../../example/lib/main.dart#untrack-section [untrack()]

:::
