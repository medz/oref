import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('Batch', () {
    test('batches multiple signal updates', () {
      int effectCount = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);

      effect(null, () {
        a();
        b();
        effectCount++;
      });

      expect(effectCount, equals(1));

      batch(() {
        a(10);
        b(20);
      });

      expect(effectCount, equals(2)); // Should run only once after batch
    });

    test('returns value from batch', () {
      final result = batch(() {
        return 42;
      });

      expect(result, equals(42));
    });

    test('batches computed updates', () {
      int effectCount = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);
      final sum = computed(null, (_) => a() + b());

      effect(null, () {
        sum();
        effectCount++;
      });

      expect(effectCount, equals(1));
      expect(sum(), equals(3));

      batch(() {
        a(10);
        b(20);
      });

      expect(effectCount, equals(2)); // Should run only once
      expect(sum(), equals(30));
    });

    test('nested batches', () {
      int effectCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        effectCount++;
      });

      expect(effectCount, equals(1));

      batch(() {
        count(1);
        batch(() {
          count(2);
          count(3);
        });
        count(4);
      });

      expect(effectCount, equals(2)); // Should run only once after outer batch
      expect(count(), equals(4));
    });

    test('batch with exception', () {
      int effectCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        effectCount++;
      });

      expect(effectCount, equals(1));

      expect(() {
        batch(() {
          count(1);
          throw Exception('test error');
        });
      }, throwsException);

      expect(effectCount, equals(2)); // Effect should still run
      expect(count(), equals(1));
    });

    test('batch with multiple effects', () {
      int effect1Count = 0;
      int effect2Count = 0;
      final a = signal(null, 1);
      final b = signal(null, 2);

      effect(null, () {
        a();
        effect1Count++;
      });

      effect(null, () {
        b();
        effect2Count++;
      });

      expect(effect1Count, equals(1));
      expect(effect2Count, equals(1));

      batch(() {
        a(10);
        b(20);
      });

      expect(effect1Count, equals(2));
      expect(effect2Count, equals(2));
    });

    test('batch updates do not trigger until complete', () {
      final values = <int>[];
      final count = signal(null, 0);

      effect(null, () {
        values.add(count());
      });

      expect(values, equals([0]));

      batch(() {
        count(1);
        expect(values, equals([0])); // Should not have updated yet
        count(2);
        expect(values, equals([0])); // Should not have updated yet
        count(3);
        expect(values, equals([0])); // Should not have updated yet
      });

      expect(values, equals([0, 3])); // Should update after batch
    });

    test('batch with signal chaining', () {
      int effectCount = 0;
      final a = signal(null, 1);
      final b = computed(null, (_) => a() * 2);
      final c = computed(null, (_) => b() * 2);

      effect(null, () {
        c();
        effectCount++;
      });

      expect(effectCount, equals(1));
      expect(c(), equals(4));

      batch(() {
        a(2);
        a(3);
        a(4);
      });

      expect(effectCount, equals(2));
      expect(c(), equals(16));
    });

    test('batch with conditional updates', () {
      int effectCount = 0;
      final flag = signal(null, true);
      final a = signal(null, 1);
      final b = signal(null, 2);

      effect(null, () {
        flag() ? a() : b();
        effectCount++;
      });

      expect(effectCount, equals(1));

      batch(() {
        a(10);
        b(20);
      });

      expect(effectCount, equals(2)); // Only 'a' is tracked

      flag(false);
      expect(effectCount, equals(3));

      batch(() {
        a(30);
        b(40);
      });

      expect(effectCount, equals(4)); // Only 'b' is tracked now
    });

    test('empty batch does nothing', () {
      int effectCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        effectCount++;
      });

      expect(effectCount, equals(1));

      batch(() {
        // Do nothing
      });

      expect(effectCount, equals(1)); // Should not trigger effect
    });
  });
}
