import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('ReactiveSet', () {
    test('creates set with initial elements', () {
      final set = ReactiveSet([1, 2, 3]);
      expect(set.length, equals(3));
      expect(set.contains(1), isTrue);
      expect(set.contains(2), isTrue);
      expect(set.contains(3), isTrue);
    });

    test('tracks length access', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2, 3]);

      effect(null, () {
        set.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.add(4);
      expect(effectCount, equals(2));
    });

    test('tracks contains check', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2, 3]);

      effect(null, () {
        set.contains(1);
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.add(4);
      expect(effectCount, equals(2));
    });

    test('add triggers effects', () {
      int effectCount = 0;
      final set = ReactiveSet<int>([]);

      effect(null, () {
        set.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.add(1);
      expect(effectCount, equals(2));
      expect(set.length, equals(1));
    });

    test('add returns true for new element', () {
      final set = ReactiveSet([1, 2, 3]);

      final added = set.add(4);
      expect(added, isTrue);
      expect(set.contains(4), isTrue);

      final notAdded = set.add(1);
      expect(notAdded, isFalse);
      expect(set.length, equals(4));
    });

    test('remove triggers effects', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2, 3]);

      effect(null, () {
        set.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.remove(2);
      expect(effectCount, equals(2));
      expect(set.length, equals(2));
    });

    test('remove returns true when element removed', () {
      final set = ReactiveSet([1, 2, 3]);

      final removed = set.remove(2);
      expect(removed, isTrue);
      expect(set.contains(2), isFalse);

      final notRemoved = set.remove(5);
      expect(notRemoved, isFalse);
    });

    test('clear triggers effects', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2, 3]);

      effect(null, () {
        set.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.clear();
      expect(effectCount, equals(2));
      expect(set.length, equals(0));
    });

    test('tracks iteration', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2, 3]);

      effect(null, () {
        for (var item in set) {
          item; // Access each item
        }
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.add(4);
      expect(effectCount, equals(2));
    });

    test('tracks lookup', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2, 3]);

      effect(null, () {
        set.lookup(2);
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.add(4);
      expect(effectCount, equals(2));
    });

    test('batch updates on set', () {
      int effectCount = 0;
      final set = ReactiveSet<int>([]);

      effect(null, () {
        set.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      batch(() {
        set.add(1);
        set.add(2);
        set.add(3);
      });

      expect(effectCount, equals(2)); // Should trigger only once
      expect(set.length, equals(3));
    });

    test('untrack set access', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2, 3]);

      effect(null, () {
        untrack(() => set.length);
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.add(4);
      expect(effectCount, equals(1)); // Should not trigger
    });

    test('computed from set', () {
      final set = ReactiveSet([1, 2, 3]);
      final sum = computed(null, (_) {
        return set.fold<int>(0, (acc, item) => acc + item);
      });

      expect(sum(), equals(6));

      set.add(4);
      expect(sum(), equals(10));

      set.remove(1);
      expect(sum(), equals(9));
    });

    test('multiple effects on same set', () {
      int effect1Count = 0;
      int effect2Count = 0;
      final set = ReactiveSet([1, 2, 3]);

      effect(null, () {
        set.length;
        effect1Count++;
      });

      effect(null, () {
        set.contains(1);
        effect2Count++;
      });

      expect(effect1Count, equals(1));
      expect(effect2Count, equals(1));

      set.add(4);
      expect(effect1Count, equals(2));
      expect(effect2Count, equals(2));

      set.remove(1);
      expect(effect1Count, equals(3));
      expect(effect2Count, equals(3));
    });

    test('set prevents duplicates', () {
      final set = ReactiveSet([1, 2, 3]);

      expect(set.length, equals(3));

      set.add(1);
      expect(set.length, equals(3)); // No duplicate

      set.add(4);
      expect(set.length, equals(4));
    });

    test('empty set operations', () {
      final set = ReactiveSet<int>([]);

      expect(set.isEmpty, isTrue);
      expect(set.isNotEmpty, isFalse);
      expect(set.length, equals(0));

      set.add(1);
      expect(set.isEmpty, isFalse);
      expect(set.isNotEmpty, isTrue);
    });

    test('toSet creates new set', () {
      final reactive = ReactiveSet([1, 2, 3]);
      final regular = reactive.toSet();

      expect(regular, equals({1, 2, 3}));
      expect(regular, isA<Set<int>>());
    });

    test('addAll triggers effects', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2]);

      effect(null, () {
        set.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.addAll([3, 4, 5]);
      expect(effectCount, equals(2)); // Triggers once per operation
      expect(set.length, equals(5));
    });

    test('removeAll triggers effects', () {
      int effectCount = 0;
      final set = ReactiveSet([1, 2, 3, 4, 5]);

      effect(null, () {
        set.length;
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.removeAll([2, 4]);
      expect(effectCount, equals(2)); // Triggers once per operation
      expect(set.length, equals(3));
    });

    test('union operation', () {
      final set1 = ReactiveSet([1, 2, 3]);
      final set2 = {3, 4, 5};

      final union = set1.union(set2);
      expect(union.length, equals(5));
      expect(union, equals({1, 2, 3, 4, 5}));
    });

    test('intersection operation', () {
      final set1 = ReactiveSet([1, 2, 3, 4]);
      final set2 = {3, 4, 5, 6};

      final intersection = set1.intersection(set2);
      expect(intersection.length, equals(2));
      expect(intersection, equals({3, 4}));
    });

    test('difference operation', () {
      final set1 = ReactiveSet([1, 2, 3, 4]);
      final set2 = {3, 4, 5, 6};

      final difference = set1.difference(set2);
      expect(difference.length, equals(2));
      expect(difference, equals({1, 2}));
    });

    test('set with string elements', () {
      final set = ReactiveSet(['apple', 'banana', 'cherry']);

      expect(set.length, equals(3));
      expect(set.contains('apple'), isTrue);

      set.add('date');
      expect(set.length, equals(4));

      set.remove('banana');
      expect(set.length, equals(3));
      expect(set.contains('banana'), isFalse);
    });
  });
}
