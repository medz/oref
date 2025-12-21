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

## Flutter Example (from the example app)

::: code-group

<<< ../../example/lib/main.dart#effect-batch-section [Effect + batch]

:::
