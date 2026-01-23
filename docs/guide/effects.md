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

## Widget Lifecycle Hooks

Use these hooks to run one-time effects tied to a widget element's lifecycle.
They are lightweight helpers built on memoization and element tracking.

### When to use
- Show a one-time toast/snackbar after the first frame.
- Start or schedule work once and dispose/cancel it when the widget leaves.
- Attach listeners that should live as long as the widget element does.

### When not to use
- If you need reactive re-runs based on signals, use `effect`.
- If you need cleanup for an `effect`, use `onEffectDispose`.
- If you need per-build logic, keep it in `build`.

### Behavior
- `onMounted`: runs once after the first frame for the current element.
- `onUnmounted`: runs once when the element is removed from the tree
  (triggered on the next frame).
- Both will run again after a full unmount + remount.

### Common pitfalls
- Must be called inside `build` (or a `Builder`), not across async gaps.
- Must be called unconditionally and in the same order every rebuild.
- `onUnmounted` runs on the next frame, so tests must `pump()` after removal.

### Example

```dart
Builder(
  builder: (context) {
    onMounted(context, () {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mounted')));
    });

    final timer = Timer(const Duration(seconds: 5), () {
      debugPrint('tick');
    });
    onUnmounted(context, timer.cancel);

    return const SizedBox();
  },
);
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
