# Core Concepts

## Signals

A signal is a reactive container. Read it by calling it, write with `.set(...)`.

```dart
final name = signal(context, 'Oref');
name(); // read
name.set('Oref v2'); // write
```

## Nullable Context (Widget-bound vs Global)

All core APIs accept `BuildContext?`. When you pass a **widget context**, Oref
memoizes the reactive node and disposes it with the widget. When you pass
`null`, the node becomes **global/standalone** and you must manage cleanup.

```dart
// Inside a widget build -> auto-bound & auto-disposed
final count = signal(context, 0);
effect(context, () => debugPrint('count: ${count()}'));

// Outside widgets -> pass null and clean up manually
final globalCount = signal<int>(null, 0);
final stop = effect(null, () => debugPrint('global: ${globalCount()}'));

// later...
stop(); // dispose effect
```

## Write API in Practice

Signals are callables, not mutable fields. To update, read then `.set(...)`:

```dart
final count = signal(context, 0);

void increment() {
  count.set(count() + 1);
}

void reset() {
  count.set(0);
}
```

## Computed

Computed values derive from signals and cache automatically.

```dart
final count = signal(context, 2);
final squared = computed(context, (_) => count() * count());
```

## Writable Computed

A writable computed value can map writes back to a source.

```dart
import 'dart:math' as math;

final count = signal<double>(context, 0);
final squared = writableComputed<double>(
  context,
  get: (_) => count() * count(),
  set: (value) => count.set(math.sqrt(value)),
);
```

## Effects

Effects track dependencies and re-run when signals change.

```dart
final count = signal(context, 0);

effect(context, () {
  debugPrint('count = ${count()}');
});
```

## Batch and Untrack

Batch multiple updates to avoid extra recomputations:

```dart
batch(() {
  a.set(1);
  b.set(2);
});
```

Use `untrack` when you want to read without subscribing:

```dart
final value = untrack(() => count());
```
