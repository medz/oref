# Effect 与批处理

## 基础 Effect

```dart
final count = signal(context, 0);
final stop = effect(context, () {
  debugPrint('count = ${count()}');
});

// 手动停止
stop();
```

## Effect 生命周期（首次执行）

Effect 会**立即执行一次**，随后在依赖变化时重新运行。如果要跳过首次执行：

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

## 清理回调

`onEffectCleanup` 用于重新执行前清理，`onEffectDispose` 用于最终清理。

```dart
effect(context, () {
  onEffectCleanup(() => debugPrint('cleanup before re-run'));
  onEffectDispose(() => debugPrint('dispose'));
});
```

## EffectScope

```dart
final scope = effectScope(context, () {
  effect(context, () => debugPrint('A'));
  effect(context, () => debugPrint('B'));
});

scope(); // 释放范围内所有 effect
```

## 批处理更新

```dart
batch(() {
  a.set(a() + 1);
  b.set(b() + 1);
});
```
