import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

class _OpaqueValue {
  @override
  String toString() => throw StateError('Values must not be inspected');
}

class _SinglePassIterable<T> extends IterableBase<T> {
  _SinglePassIterable(this.values);

  final List<T> values;
  bool _iterated = false;

  @override
  Iterator<T> get iterator {
    if (_iterated) throw StateError('Iterable was consumed more than once');
    _iterated = true;
    return values.iterator;
  }
}

void main() {
  test('list mutations do not stringify user values', () {
    final first = _OpaqueValue();
    final second = _OpaqueValue();
    final list = ReactiveList<_OpaqueValue>([]);

    list.add(first);
    list[0] = second;
    list.addAll([first]);
    list.insert(0, first);
    expect(list.remove(first), isTrue);
    expect(identical(list.removeAt(0), second), isTrue);
    list.clear();
    expect(list, isEmpty);
  });

  test('map mutations do not stringify keys or values', () {
    final key = _OpaqueValue();
    final otherKey = _OpaqueValue();
    final first = _OpaqueValue();
    final second = _OpaqueValue();
    final map = ReactiveMap<_OpaqueValue, _OpaqueValue>({});

    map[key] = first;
    map[key] = second;
    expect(identical(map.putIfAbsent(otherKey, () => first), first), isTrue);
    expect(identical(map.remove(key), second), isTrue);
    map.clear();
    expect(map, isEmpty);
  });

  test('set mutations do not stringify user values', () {
    final first = _OpaqueValue();
    final second = _OpaqueValue();
    final set = ReactiveSet<_OpaqueValue>([]);

    expect(set.add(first), isTrue);
    set.addAll([second]);
    expect(set.remove(first), isTrue);
    set.removeAll([second]);
    set.clear();
    expect(set, isEmpty);
  });

  test('bulk collection mutations consume their input only once', () {
    final list = ReactiveList<int>([]);
    list.addAll(_SinglePassIterable([1, 2, 3]));
    expect(list, [1, 2, 3]);

    final set = ReactiveSet<int>([]);
    set.addAll(_SinglePassIterable([1, 2, 3]));
    expect(set, {1, 2, 3});
    set.removeAll(_SinglePassIterable([1, 3]));
    expect(set, {2});
  });
}
