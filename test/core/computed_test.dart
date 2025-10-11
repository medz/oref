import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('Computed', () {
    test('computes value from signals', () {
      final count = signal(null, 5);
      final doubled = computed(null, (_) => count() * 2);

      expect(doubled(), equals(10));
    });

    test('updates when dependency changes', () {
      final count = signal(null, 5);
      final doubled = computed(null, (_) => count() * 2);

      expect(doubled(), equals(10));

      count(10);
      expect(doubled(), equals(20));
    });

    test('computes from multiple signals', () {
      final a = signal(null, 2);
      final b = signal(null, 3);
      final sum = computed(null, (_) => a() + b());

      expect(sum(), equals(5));

      a(5);
      expect(sum(), equals(8));

      b(10);
      expect(sum(), equals(15));
    });

    test('chains computed values', () {
      final count = signal(null, 2);
      final doubled = computed(null, (_) => count() * 2);
      final quadrupled = computed(null, (_) => doubled() * 2);

      expect(quadrupled(), equals(8));

      count(5);
      expect(quadrupled(), equals(20));
    });

    test('computed triggers effects', () {
      int effectCount = 0;
      final count = signal(null, 5);
      final doubled = computed(null, (_) => count() * 2);

      effect(null, () {
        doubled();
        effectCount++;
      });

      expect(effectCount, equals(1));

      count(10);
      expect(effectCount, equals(2));
    });

    test('computed is lazy', () {
      int computeCount = 0;
      final count = signal(null, 5);
      final doubled = computed(null, (_) {
        computeCount++;
        return count() * 2;
      });

      expect(computeCount, equals(0));

      doubled();
      expect(computeCount, equals(1));

      doubled();
      expect(computeCount, equals(1)); // Should be cached
    });

    test('computed with previous value', () {
      final count = signal(null, 1);
      final accumulated = computed<int>(null, (prev) {
        return (prev ?? 0) + count();
      });

      expect(accumulated(), equals(1));

      count(2);
      expect(accumulated(), equals(3)); // 1 + 2

      count(3);
      expect(accumulated(), equals(6)); // 3 + 3
    });

    test('computed with conditional dependencies', () {
      final condition = signal(null, true);
      final a = signal(null, 1);
      final b = signal(null, 2);

      final result = computed(null, (_) {
        return condition() ? a() : b();
      });

      expect(result(), equals(1));

      a(10);
      expect(result(), equals(10));

      b(20); // Should not trigger recompute
      expect(result(), equals(10));

      condition(false);
      expect(result(), equals(20));

      a(30); // Should not trigger recompute now
      expect(result(), equals(20));

      b(40);
      expect(result(), equals(40));
    });

    test('computed with complex types', () {
      final items = signal<List<int>>(null, [1, 2, 3]);
      final sum = computed(null, (_) {
        return items().reduce((a, b) => a + b);
      });

      expect(sum(), equals(6));

      items([1, 2, 3, 4]);
      expect(sum(), equals(10));
    });

    test('multiple computed values from same signal', () {
      final count = signal(null, 5);
      final doubled = computed(null, (_) => count() * 2);
      final tripled = computed(null, (_) => count() * 3);

      expect(doubled(), equals(10));
      expect(tripled(), equals(15));

      count(10);
      expect(doubled(), equals(20));
      expect(tripled(), equals(30));
    });
  });
}
