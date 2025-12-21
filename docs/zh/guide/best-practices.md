# 最佳实践

## 控制响应范围

在 widget build 内创建信号，会自动绑定到组件生命周期：

```dart
final count = signal(context, 0);
```

如果在组件外创建，请传 `null`，并手动释放 effect。

## 用 Computed 表达派生状态

派生状态尽量放在 `computed` 中：

```dart
final total = computed(context, (_) => items.length);
```

不要在 computed 内部写入值。

## 用 SignalBuilder 限制重建

只包裹需要更新的局部：

```dart
SignalBuilder(
  builder: (context) => Text('Count: ${count()}'),
);
```

适合使用 `SignalBuilder` 的场景：
- 只有局部子树依赖信号/computed
- 不想重建整棵 widget 树
- 列表项/卡片等细粒度更新

## 用 Batch 合并更新

减少重复重算：

```dart
batch(() {
  a.set(a() + 1);
  b.set(b() + 1);
});
```

适合使用 `batch` 的场景：
- 一次用户操作更新多个信号
- 集合有大量 mutation（如 sort、clear + addAll）
- 希望 effect/computed 只重新计算一次

## 集合用 ReactiveList/Map/Set

需要就地修改时使用响应式集合：

```dart
final todos = ReactiveList.scoped(context, ['A', 'B']);
todos.add('C');
```

## 控制依赖跟踪

在 effect 内使用 `untrack` 避免多余依赖：

```dart
effect(context, () {
  final snapshot = untrack(() => expensive());
  debugPrint('snapshot: $snapshot');
});
```

## Flutter 示例（来自 example 应用）

::: code-group

<<< ../../../example/lib/main.dart#counter-section [Counter + computed + writableComputed]

<<< ../../../example/lib/main.dart#effect-batch-section [Effect + batch]

<<< ../../../example/lib/main.dart#untrack-section [untrack()]

:::
