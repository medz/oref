# 集合类型

Oref 提供响应式的 List、Map 与 Set 封装。

## ReactiveList

```dart
final items = ReactiveList<int>.scoped(context, [1, 2, 3]);

items.add(4);
```

### 排序

```dart
batch(() {
  items.sort((a, b) => a.compareTo(b));
});
```

### 去重

```dart
batch(() {
  final unique = items.toSet().toList();
  items
    ..clear()
    ..addAll(unique);
});
```

### 批量更新

```dart
batch(() {
  for (var i = 0; i < items.length; i++) {
    items[i] = items[i] * 2;
  }
});
```

## ReactiveMap

```dart
final map = ReactiveMap<String, int>.scoped(context, {'a': 1});

map['b'] = 2;
```

### 批量更新

```dart
batch(() {
  map['a'] = 10;
  map['b'] = 20;
});
```

### 批量删除

```dart
batch(() {
  for (final key in ['a', 'b']) {
    map.remove(key);
  }
});
```

## ReactiveSet

```dart
final tags = ReactiveSet<String>.scoped(context, {'flutter'});

tags.add('signals');
```

### 去重

```dart
batch(() {
  tags.addAll(['signals', 'fast', 'signals']);
});
```

### 批量增删

```dart
batch(() {
  tags.addAll(['async', 'widget']);
  tags.removeAll(['fast']);
});
```

读取会 `track()`，写入会 `trigger()`，因此访问过的 UI 会在变化时自动更新。

## Flutter 示例（来自 example 应用）

::: code-group

<<< ../../../example/lib/main.dart#walkthrough-section [Walkthrough: searchable list]

<<< ../../../example/lib/main.dart#reactive-map-section [ReactiveMap]

<<< ../../../example/lib/main.dart#reactive-set-section [ReactiveSet]

:::
