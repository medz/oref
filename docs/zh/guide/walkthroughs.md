# 上手示例

## 可搜索列表

这个示例结合了查询信号、响应式列表和 computed 过滤。

```dart
final query = signal(context, '');
final items = ReactiveList.scoped(context, [
  'Aurora',
  'Comet',
  'Nebula',
  'Orion',
  'Pulsar',
]);

final filtered = computed<List<String>>(context, (_) {
  final q = query().trim().toLowerCase();
  if (q.isEmpty) return List.unmodifiable(items);
  return items.where((item) => item.toLowerCase().contains(q)).toList();
});
```

UI 接线示例：

```dart
TextField(
  decoration: const InputDecoration(labelText: 'Search'),
  onChanged: query.set,
);

SignalBuilder(
  builder: (context) {
    final results = filtered();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('显示 ${results.length} 项'),
        for (final item in results) Text(item),
      ],
    );
  },
);
```

可以在示例应用中直接体验。

## 结算总价 + 自动保存

这个流程把 `.set(...)`、`computed` 和 `effect` 组合在一起。

```dart
final qty = signal(context, 1);
final unitPrice = signal(context, 19.0);
final discount = signal(context, 0.0); // 0%..30%

final subtotal = computed<double>(context, (_) => qty() * unitPrice());
final total = computed<double>(context, (_) => subtotal() * (1 - discount()));

final saves = signal(context, 0);
effect(context, () {
  total(); // 追踪 computed
  final current = untrack(() => saves());
  saves.set(current + 1); // 自动保存次数
});
```

用 `.set(...)` 更新输入：

```dart
qty.set(qty() + 1);
discount.set(0.1); // 10% 活动
unitPrice.set(24.0);
```

## Flutter 示例（来自 example 应用）

::: code-group

<<< ../../../example/lib/main.dart#walkthrough-section [Walkthrough: searchable list]

<<< ../../../example/lib/main.dart#checkout-workflow-section [Walkthrough: checkout total + autosave]

:::
