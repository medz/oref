# Collections

Oref provides reactive wrappers for lists, maps, and sets.

## ReactiveList

```dart
final items = ReactiveList<int>.scoped(context, [1, 2, 3]);

items.add(4);
```

### Sorting

```dart
batch(() {
  items.sort((a, b) => a.compareTo(b));
});
```

### De-duplication

```dart
batch(() {
  final unique = items.toSet().toList();
  items
    ..clear()
    ..addAll(unique);
});
```

### Bulk update

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

### Bulk update

```dart
batch(() {
  map['a'] = 10;
  map['b'] = 20;
});
```

### Remove a group

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

### De-duplication

```dart
batch(() {
  tags.addAll(['signals', 'fast', 'signals']);
});
```

### Bulk add/remove

```dart
batch(() {
  tags.addAll(['async', 'widget']);
  tags.removeAll(['fast']);
});
```

These collections call `track()` on reads and `trigger()` on writes, so widgets rebuild when accessed values change.

## Flutter Examples (from the example app)

::: code-group

<<< ../../example/lib/main.dart#walkthrough-section [Walkthrough: searchable list]

<<< ../../example/lib/main.dart#reactive-map-section [ReactiveMap]

<<< ../../example/lib/main.dart#reactive-set-section [ReactiveSet]

:::
