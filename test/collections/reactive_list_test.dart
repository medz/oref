import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('ReactiveList', () {
    test('creates list with initial elements', () {
      final list = ReactiveList([1, 2, 3]);
      expect(list.length, equals(3));
      expect(list[0], equals(1));
      expect(list[1], equals(2));
      expect(list[2], equals(3));
    });

    test('tracks length access', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.add(4);
      expect(effectCount, equals(2));
    });

    test('tracks element access', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        list[0];
        effectCount++;
      });

      expect(effectCount, equals(1));

      list[0] = 10;
      expect(effectCount, equals(2));
      expect(list[0], equals(10));
    });

    test('add triggers effects', () {
      int effectCount = 0;
      final list = ReactiveList<int>([]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.add(1);
      expect(effectCount, equals(2));
      expect(list.length, equals(1));
    });

    test('remove triggers effects', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.remove(2);
      expect(effectCount, equals(2));
      expect(list.length, equals(2));
    });

    test('removeAt triggers effects', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.removeAt(1);
      expect(effectCount, equals(2));
      expect(list.length, equals(2));
      expect(list[1], equals(3));
    });

    test('clear triggers effects', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.clear();
      expect(effectCount, equals(2));
      expect(list.length, equals(0));
    });

    test('insert triggers effects', () {
      int effectCount = 0;
      final list = ReactiveList([1, 3]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.insert(1, 2);
      expect(effectCount, equals(2));
      expect(list.length, equals(3));
      expect(list[1], equals(2));
    });

    test('addAll triggers effects', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.addAll([3, 4, 5]);
      expect(effectCount, equals(2));
      expect(list.length, equals(5));
    });

    test('set length triggers effects', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3, 4, 5]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.length = 3;
      expect(effectCount, equals(2));
      expect(list.length, equals(3));
    });

    test('tracks iteration', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        for (var item in list) {
          item; // Access each item
        }
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.add(4);
      expect(effectCount, equals(2));
    });

    test('tracks map operation', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        list.map((e) => e * 2).toList();
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.add(4);
      expect(effectCount, equals(2));
    });

    test('tracks where operation', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3, 4]);

      effect(null, () {
        list.where((e) => e > 2).toList();
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.add(5);
      expect(effectCount, equals(2));
    });

    test('batch updates on list', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        list.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      batch(() {
        list.add(4);
        list.add(5);
        list.add(6);
      });

      expect(effectCount, equals(2)); // Should trigger only once
      expect(list.length, equals(6));
    });

    test('untrack list access', () {
      int effectCount = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        untrack(() => list.length);
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.add(4);
      expect(effectCount, equals(1)); // Should not trigger
    });

    test('computed from list', () {
      final list = ReactiveList([1, 2, 3]);
      final sum = computed(null, (_) {
        return list.fold<int>(0, (acc, item) => acc + item);
      });

      expect(sum(), equals(6));

      list.add(4);
      expect(sum(), equals(10));

      list[0] = 10;
      expect(sum(), equals(19));
    });

    test('multiple effects on same list', () {
      int effect1Count = 0;
      int effect2Count = 0;
      final list = ReactiveList([1, 2, 3]);

      effect(null, () {
        list.length;
        effect1Count++;
      });

      effect(null, () {
        list[0];
        effect2Count++;
      });

      expect(effect1Count, equals(1));
      expect(effect2Count, equals(1));

      list.add(4);
      expect(effect1Count, equals(2));
      expect(effect2Count, equals(2)); // coarse-grained: any mutation triggers all effects

      list[0] = 10;
      expect(effect1Count, equals(3)); // coarse-grained: any mutation triggers all effects
      expect(effect2Count, equals(3));
    });

    test('list with complex objects', () {
      final list = ReactiveList<Map<String, int>>([
        {'a': 1},
        {'b': 2}
      ]);

      expect(list[0]['a'], equals(1));
      expect(list[1]['b'], equals(2));

      list.add({'c': 3});
      expect(list.length, equals(3));
      expect(list[2]['c'], equals(3));
    });

    test('empty list operations', () {
      final list = ReactiveList<int>([]);

      expect(list.isEmpty, isTrue);
      expect(list.isNotEmpty, isFalse);
      expect(list.length, equals(0));

      list.add(1);
      expect(list.isEmpty, isFalse);
      expect(list.isNotEmpty, isTrue);
    });
  });
}
