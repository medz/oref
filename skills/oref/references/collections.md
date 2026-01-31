# Collections

Oref provides reactive wrappers for lists, maps, and sets. Prefer `*.scoped(context, ...)` inside `build`.

## ReactiveList

```dart
final items = ReactiveList<int>.scoped(context, [1, 2, 3]);
items.add(4);
```

Bulk update with `batch`:

```dart
batch(() {
  items.sort((a, b) => a.compareTo(b));
});
```

## ReactiveMap

```dart
final map = ReactiveMap<String, int>.scoped(context, {'a': 1});
map['b'] = 2;
```

Bulk update with `batch`:

```dart
batch(() {
  map['a'] = 10;
  map['b'] = 20;
});
```

## ReactiveSet

```dart
final tags = ReactiveSet<String>.scoped(context, {'flutter'});

tags.add('signals');
```

Batch add/remove:

```dart
batch(() {
  tags.addAll(['async', 'widget']);
  tags.removeAll(['fast']);
});
```

These collections call `track()` on reads and `trigger()` on writes, so widgets rebuild when accessed values change.
