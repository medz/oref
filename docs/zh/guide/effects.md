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

## 清理回调

`onEffectCleanup` 用于重新执行前清理，`onEffectDispose` 用于最终清理。

```dart
effect(context, () {
  onEffectCleanup(() => debugPrint('cleanup before re-run'));
  onEffectDispose(() => debugPrint('dispose'));
});
```

## Widget 生命周期钩子

这些钩子用于把一次性的副作用和组件生命周期绑定在一起，
底层基于记忆化与 Element 跟踪。

### 何时使用
- 首帧结束后展示一次提示（toast/snackbar）。
- 启动一次性任务，并在组件移除时取消/释放。
- 监听器的生命周期需要与组件一致。

### 不适用场景
- 需要响应式重跑：用 `effect`。
- 需要清理 `effect`：用 `onEffectDispose`。
- 需要每次 build 运行：直接放在 `build`。

### 行为说明
- `onMounted`：首帧结束后执行一次。
- `onUnmounted`：组件从树中移除时执行一次（下一帧触发）。
- 卸载再挂载会再次触发。

### 常见坑
- 必须在 `build`（或 `Builder`）里调用，避免跨异步调用。
- 每次 build 的调用顺序必须一致且不可条件化。
- `onUnmounted` 在下一帧触发，测试中需要 `pump()`。

### 示例

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

## Flutter 示例（来自 example 应用）

::: code-group

<<< ../../../example/lib/main.dart#effect-batch-section [Effect + batch]

:::
