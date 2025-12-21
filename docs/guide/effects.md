# Effects & Batching

## Basic Effect

```dart
final count = signal(context, 0);
final stop = effect(context, () {
  debugPrint('count = ${count()}');
});

// stop the effect manually
stop();
```

## Effect Lifecycle (Initial Run)

Effects run **once immediately**, then re-run when dependencies change. If you
need to skip the initial run:

```dart
var first = true;

effect(context, () {
  if (first) {
    first = false;
    return;
  }
  debugPrint('changed: ${count()}');
});
```

## Cleanup Hooks

Use `onEffectCleanup` for re-run cleanup, and `onEffectDispose` for final cleanup.

```dart
effect(context, () {
  onEffectCleanup(() => debugPrint('cleanup before re-run'));
  onEffectDispose(() => debugPrint('dispose'));
});
```

## Effect Scope

```dart
final scope = effectScope(context, () {
  effect(context, () => debugPrint('A'));
  effect(context, () => debugPrint('B'));
});

scope(); // dispose all effects in the scope
```

## Batch Updates

```dart
batch(() {
  a.set(a() + 1);
  b.set(b() + 1);
});
```
