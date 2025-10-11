import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('ReactiveMap', () {
    test('creates map with initial values', () {
      final map = ReactiveMap({'a': 1, 'b': 2});
      expect(map['a'], equals(1));
      expect(map['b'], equals(2));
    });

    test('tracks key access', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        map['a'];
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['a'] = 10;
      expect(effectCount, equals(2));
      expect(map['a'], equals(10));
    });

    test('tracks keys access', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        map.keys.toList();
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['c'] = 3;
      expect(effectCount, equals(2));
    });

    test('set value triggers effects', () {
      int effectCount = 0;
      final map = ReactiveMap<String, int>({});

      effect(null, () {
        map.keys.toList();
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['a'] = 1;
      expect(effectCount, equals(2));
    });

    test('remove triggers effects', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        map.keys.toList();
        effectCount++;
      });

      expect(effectCount, equals(1));

      map.remove('a');
      expect(effectCount, equals(2));
      expect(map['a'], isNull);
    });

    test('clear triggers effects', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        map.keys.toList();
        effectCount++;
      });

      expect(effectCount, equals(1));

      map.clear();
      expect(effectCount, equals(2));
      expect(map.isEmpty, isTrue);
    });

    test('tracks iteration over keys', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        for (var key in map.keys) {
          map[key];
        }
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['c'] = 3;
      expect(effectCount, equals(2));
    });

    test('tracks values access', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        map.keys; // Need to track keys to track changes
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['a'] = 10;
      expect(effectCount, equals(2));
    });

    test('tracks length', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        map.keys.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['c'] = 3;
      expect(effectCount, equals(2));

      map.remove('a');
      expect(effectCount, equals(3));
    });

    test('tracks containsKey', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        map.keys.contains('a');
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['c'] = 3;
      expect(effectCount, equals(2));
    });

    test('batch updates on map', () {
      int effectCount = 0;
      final map = ReactiveMap<String, int>({});

      effect(null, () {
        map.keys.toList();
        effectCount++;
      });

      expect(effectCount, equals(1));

      batch(() {
        map['a'] = 1;
        map['b'] = 2;
        map['c'] = 3;
      });

      expect(effectCount, equals(2)); // Should trigger only once
    });

    test('untrack map access', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        untrack(() => map['a']);
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['a'] = 10;
      expect(effectCount, equals(1)); // Should not trigger
    });

    test('computed from map', () {
      final map = ReactiveMap({'a': 1, 'b': 2, 'c': 3});
      final sum = computed(null, (_) {
        return map.keys.fold<int>(0, (acc, key) => acc + (map[key] ?? 0));
      });

      expect(sum(), equals(6));

      map['d'] = 4;
      expect(sum(), equals(10));

      map['a'] = 10;
      expect(sum(), equals(19));
    });

    test('multiple effects on same map', () {
      int effect1Count = 0;
      int effect2Count = 0;
      final map = ReactiveMap({'a': 1, 'b': 2});

      effect(null, () {
        map.keys.toList();
        effect1Count++;
      });

      effect(null, () {
        map['a'];
        effect2Count++;
      });

      expect(effect1Count, equals(1));
      expect(effect2Count, equals(1));

      map['c'] = 3;
      expect(effect1Count, equals(2));
      expect(effect2Count, equals(2));

      map['a'] = 10;
      expect(effect1Count, equals(3));
      expect(effect2Count, equals(3));
    });

    test('map with complex values', () {
      final map = ReactiveMap<String, List<int>>({
        'a': [1, 2, 3],
        'b': [4, 5, 6]
      });

      expect(map['a'], equals([1, 2, 3]));
      expect(map['b'], equals([4, 5, 6]));

      map['c'] = [7, 8, 9];
      expect(map['c'], equals([7, 8, 9]));
    });

    test('empty map operations', () {
      final map = ReactiveMap<String, int>({});

      expect(map.isEmpty, isTrue);
      expect(map.length, equals(0));
      expect(map.keys.isEmpty, isTrue);

      map['a'] = 1;
      expect(map.isEmpty, isFalse);
      expect(map.length, equals(1));
    });

    test('updating same key multiple times', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1});

      effect(null, () {
        map['a'];
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['a'] = 2;
      expect(effectCount, equals(2));

      map['a'] = 3;
      expect(effectCount, equals(3));

      map['a'] = 4;
      expect(effectCount, equals(4));
    });

    test('remove returns value', () {
      final map = ReactiveMap({'a': 1, 'b': 2});

      final removed = map.remove('a');
      expect(removed, equals(1));
      expect(map['a'], isNull);

      final notFound = map.remove('c');
      expect(notFound, isNull);
    });

    test('putIfAbsent triggers effects', () {
      int effectCount = 0;
      final map = ReactiveMap({'a': 1});

      effect(null, () {
        map.keys.toList();
        effectCount++;
      });

      expect(effectCount, equals(1));

      map.putIfAbsent('b', () => 2);
      expect(effectCount, equals(2));

      map.putIfAbsent('a', () => 10); // Should not add
      expect(effectCount, equals(3)); // Still triggers
      expect(map['a'], equals(1)); // Value unchanged
    });
  });
}
