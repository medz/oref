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
