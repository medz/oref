import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('Signal', () {
    test('creates signal with initial value', () {
      final count = signal(null, 0);
      expect(count(), equals(0));
    });

    test('updates signal value', () {
      final count = signal(null, 0);
      count(5);
      expect(count(), equals(5));
    });

    test('returns updated value', () {
      final count = signal(null, 0);
      final result = count(10);
      expect(result, equals(10));
      expect(count(), equals(10));
    });

    test('works with different types', () {
      final text = signal(null, 'hello');
      expect(text(), equals('hello'));
      text('world');
      expect(text(), equals('world'));
    });

    test('works with nullable types', () {
      final value = signal<String?>(null, null);
      expect(value(), isNull);
      value('test');
      expect(value(), equals('test'));
      value(null, true);
      expect(value(), isNull);
    });

    test('signal triggers effects', () {
      int effectCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        effectCount++;
      });

      expect(effectCount, equals(1));

      count(1);
      expect(effectCount, equals(2));

      count(2);
      expect(effectCount, equals(3));
    });

    test('multiple signals in one effect', () {
      int effectCount = 0;
      final count1 = signal(null, 0);
      final count2 = signal(null, 0);

      effect(null, () {
        count1();
        count2();
        effectCount++;
      });

      expect(effectCount, equals(1));

      count1(1);
      expect(effectCount, equals(2));

      count2(1);
      expect(effectCount, equals(3));
    });

    test('signal with complex objects', () {
      final obj = signal<Map<String, int>>(null, {'a': 1});
      expect(obj()['a'], equals(1));

      obj({'b': 2});
      expect(obj()['b'], equals(2));
      expect(obj()['a'], isNull);
    });

    test('signal does not trigger on same value without nulls flag', () {
      int effectCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        effectCount++;
      });

      expect(effectCount, equals(1));

      count(0);
      expect(effectCount, equals(1)); // Should not trigger
    });
  });
}
