# Hooks & Lifecycle

## Hook ordering rules

- Call hooks unconditionally at the top level of a build scope.
- Do not call hooks inside control flow or nested functions.
- Use the same order on every rebuild.

## Optional-context hooks

- Inside `build`: pass `context`.
- Outside widgets: pass `null` and manage cleanup manually.

## Widget lifecycle hooks

Use these for one-time work tied to a widget element:

- `onMounted`: runs after the first frame.
- `onUnmounted`: runs when the element is removed (next frame).

```dart
Builder(
  builder: (context) {
    onMounted(context, () => debugPrint('mounted'));
    onUnmounted(context, () => debugPrint('unmounted'));
    return const SizedBox();
  },
);
```

## Effect cleanup hooks

Use inside `effect()` only:

```dart
effect(context, () {
  onEffectCleanup(() => debugPrint('cleanup before re-run'));
  onEffectDispose(() => debugPrint('dispose'));
});
```

## Scope cleanup

Use `onScopeDispose` only inside `effectScope()`.
