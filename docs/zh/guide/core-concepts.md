# 核心概念

## Signal

Signal 是响应式容器。读取用调用，写入用 `.set(...)`。

```dart
final name = signal(context, 'Oref');
name(); // 读取
name.set('Oref v2'); // 写入
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
