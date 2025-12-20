# Core Concepts

## Signals

A signal is a reactive container. Read it by calling it, write with `.set(...)`.

```dart
final name = signal(context, 'Oref');
name(); // read
name.set('Oref v2'); // write
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
