# 集合类型

Oref 提供响应式的 List、Map 与 Set 封装。

## ReactiveList

```dart
final items = ReactiveList<int>.scoped(context, [1, 2, 3]);

items.add(4);
```

## ReactiveMap

```dart
final map = ReactiveMap<String, int>.scoped(context, {'a': 1});

map['b'] = 2;
```

## ReactiveSet

```dart
final tags = ReactiveSet<String>.scoped(context, {'flutter'});

tags.add('signals');
```

读取会 `track()`，写入会 `trigger()`，因此访问过的 UI 会在变化时自动更新。
