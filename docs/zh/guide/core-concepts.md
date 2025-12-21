# 核心概念

## Signal

Signal 是响应式容器。读取用调用，写入用 `.set(...)`。

```dart
final name = signal(context, 'Oref');
name(); // 读取
name.set('Oref v2'); // 写入
```

## Context 可为空（组件绑定 vs 全局）

所有核心 API 都接受 `BuildContext?`。**传入 widget context** 时，Oref 会在
组件生命周期内缓存并自动释放；**传入 `null`** 时，节点变成**全局/独立**
实例，需要你手动清理。

```dart
// Widget build 内 -> 自动绑定 & 自动释放
final count = signal(context, 0);
effect(context, () => debugPrint('count: ${count()}'));

// Widget 外 -> 传 null 并手动释放
final globalCount = signal<int>(null, 0);
final stop = effect(null, () => debugPrint('global: ${globalCount()}'));

// later...
stop(); // 手动 dispose
```

## 写入的常见写法

Signal 不是普通字段，更新需要先读再 `.set(...)`：

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

Computed 会从信号派生并自动缓存。

```dart
final count = signal(context, 2);
final squared = computed(context, (_) => count() * count());
```

## Writable Computed

可写 Computed 可以把写入映射回源信号。

```dart
import 'dart:math' as math;

final count = signal<double>(context, 0);
final squared = writableComputed<double>(
  context,
  get: (_) => count() * count(),
  set: (value) => count.set(math.sqrt(value)),
);
```

## Effect

Effect 会追踪依赖并在变化时重新执行。

```dart
final count = signal(context, 0);

effect(context, () {
  debugPrint('count = ${count()}');
});
```

## Batch 与 Untrack

批量更新：

```dart
batch(() {
  a.set(1);
  b.set(2);
});
```

不建立依赖的读取：

```dart
final value = untrack(() => count());
```
