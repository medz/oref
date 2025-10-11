import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('Untrack', () {
    test('prevents signal from being tracked', () {
      int effectCount = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);

      effect(null, () {
        a();
        untrack(() => b());
        effectCount++;
      });

      expect(effectCount, equals(1));

      a(10);
      expect(effectCount, equals(2));

      b(20); // Should not trigger effect
      expect(effectCount, equals(2));
    });

    test('returns value from untracked computation', () {
      final count = signal(null, 5);

      final result = untrack(() => count() * 2);

      expect(result, equals(10));
    });

    test('untrack in computed', () {
      int computeCount = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);

      final result = computed(null, (_) {
        computeCount++;
        final aValue = a();
        final bValue = untrack(() => b());
        return aValue + bValue;
      });

      expect(result(), equals(3));
      expect(computeCount, equals(1));

      a(10);
      expect(result(), equals(12));
      expect(computeCount, equals(2));

      b(20); // Should not trigger recomputation
      expect(result(), equals(12)); // Still uses old b value in cache
      expect(computeCount, equals(2));

      a(15); // This will recompute and get new b value
      expect(result(), equals(35));
      expect(computeCount, equals(3));
    });

    test('nested untrack', () {
      int effectCount = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);
      final c = signal(null, 3);

      effect(null, () {
        a();
        untrack(() {
          b();
          untrack(() => c());
        });
        effectCount++;
      });

      expect(effectCount, equals(1));

      a(10);
      expect(effectCount, equals(2));

      b(20);
      expect(effectCount, equals(2));

      c(30);
      expect(effectCount, equals(2));
    });

    test('untrack with multiple signals', () {
      int effectCount = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);
      final c = signal(null, 3);

      effect(null, () {
        a();
        untrack(() {
          b();
          c();
        });
        effectCount++;
      });

      expect(effectCount, equals(1));

      a(10);
      expect(effectCount, equals(2));

      b(20);
      c(30);
      expect(effectCount, equals(2));
    });

    test('partial untrack in effect', () {
      int effectCount = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);
      final c = signal(null, 3);

      effect(null, () {
        a();
        untrack(() => b());
        c();
        effectCount++;
      });

      expect(effectCount, equals(1));

      a(10);
      expect(effectCount, equals(2));

      b(20); // Untracked, should not trigger
      expect(effectCount, equals(2));

      c(30);
      expect(effectCount, equals(3));
    });

    test('untrack with computed values', () {
      int effectCount = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);
      final sum = computed(null, (_) => a() + b());

      effect(null, () {
        untrack(() => sum());
        effectCount++;
      });

      expect(effectCount, equals(1));

      a(10);
      expect(effectCount, equals(1)); // Should not trigger

      b(20);
      expect(effectCount, equals(1)); // Should not trigger
    });

    test('untrack does not affect other effects', () {
      int effect1Count = 0;
      int effect2Count = 0;
      final count = signal(null, 1);

      effect(null, () {
        untrack(() => count());
        effect1Count++;
      });

      effect(null, () {
        count();
        effect2Count++;
      });

      expect(effect1Count, equals(1));
      expect(effect2Count, equals(1));

      count(10);
      expect(effect1Count, equals(1)); // First effect doesn't track
      expect(effect2Count, equals(2)); // Second effect tracks normally
    });

    test('untrack with side effects', () {
      final tracked = <int>[];
      final untracked = <int>[];
      final a = signal(null, 1);
      final b = signal(null, 2);

      effect(null, () {
        tracked.add(a());
        untrack(() {
          untracked.add(b());
        });
      });

      expect(tracked, equals([1]));
      expect(untracked, equals([2]));

      a(10);
      expect(tracked, equals([1, 10]));
      expect(untracked, equals([2, 2])); // b() is read again but not tracked

      b(20);
      expect(tracked, equals([1, 10])); // Effect doesn't run
      expect(untracked, equals([2, 2])); // No new entry
    });

    test('untrack returns complex types', () {
      final obj = signal<Map<String, int>>(null, {'a': 1, 'b': 2});

      final result = untrack(() => obj());

      expect(result, equals({'a': 1, 'b': 2}));
    });

    test('untrack with conditional logic', () {
      int effectCount = 0;
      final condition = signal(null, true);
      final a = signal(null, 1);
      final b = signal(null, 2);

      effect(null, () {
        if (condition()) {
          a();
        } else {
          untrack(() => b());
        }
        effectCount++;
      });

      expect(effectCount, equals(1));

      a(10);
      expect(effectCount, equals(2));

      condition(false);
      expect(effectCount, equals(3));

      b(20); // Now untracked
      expect(effectCount, equals(3));

      condition(true);
      expect(effectCount, equals(4));

      a(30);
      expect(effectCount, equals(5));
    });
  });
}
