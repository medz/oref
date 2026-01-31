# Reactivity Core

## Context rules (widget-bound vs global)

All core APIs accept `BuildContext?`.

- In `build`: pass `context` to bind to the widget lifecycle.
- Outside widgets: pass `null` and dispose effects/scopes manually.

```dart
// Widget-bound
final count = signal(context, 0);
final stop = effect(context, () => debugPrint('${count()}'));

// Global
final globalCount = signal<int>(null, 0);
final stopGlobal = effect(null, () => debugPrint('${globalCount()}'));
// later...
stopGlobal();
```

## Signals

Read by calling, write with `.set(...)`.

```dart
final name = signal(context, 'Oref');
name();
name.set('Oref v2');
```

## Computed and writableComputed

```dart
final count = signal(context, 2);
final squared = computed(context, (_) => count() * count());
```

```dart
import 'dart:math' as math;

final count = signal<double>(context, 0);
final squared = writableComputed<double>(
  context,
  get: (_) => count() * count(),
  set: (value) => count.set(math.sqrt(value)),
);
```

## Effects and cleanup

```dart
final stop = effect(context, () {
  onEffectCleanup(() => debugPrint('cleanup before re-run'));
  onEffectDispose(() => debugPrint('dispose'));
});

stop();
```

## SignalBuilder

Use `SignalBuilder` to limit rebuilds to a subtree.

```dart
SignalBuilder(
  builder: (context) {
    final count = signal(context, 0);
    return Text('Count: ${count()}');
  },
);
```

## Effect scope

```dart
final disposeScope = effectScope(context, () {
  effect(context, () => debugPrint('A'));
  effect(context, () => debugPrint('B'));
});

disposeScope();
```

## Batch and untrack

```dart
batch(() {
  a.set(1);
  b.set(2);
});

final snapshot = untrack(() => count());
```
