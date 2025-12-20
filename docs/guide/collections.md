# Collections

Oref provides reactive wrappers for lists, maps, and sets.

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

These collections call `track()` on reads and `trigger()` on writes, so widgets rebuild when accessed values change.
