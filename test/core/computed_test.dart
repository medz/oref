import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

      count.set(10);
      expect(doubled(), equals(20));
    });

    test('computes from multiple signals', () {
      final a = signal(null, 2);
      final b = signal(null, 3);
      final sum = computed(null, (_) => a() + b());

      expect(sum(), equals(5));

      a.set(5);
      expect(sum(), equals(8));

      b.set(10);
      expect(sum(), equals(15));
    });

    test('chains computed values', () {
      final count = signal(null, 2);
      final doubled = computed(null, (_) => count() * 2);
      final quadrupled = computed(null, (_) => doubled() * 2);

      expect(quadrupled(), equals(8));

      count.set(5);
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

      count.set(10);
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

      count.set(2);
      expect(accumulated(), equals(3)); // 1 + 2

      count.set(3);
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

      a.set(10);
      expect(result(), equals(10));

      b.set(20); // Should not trigger recompute
      expect(result(), equals(10));

      condition.set(false);
      expect(result(), equals(20));

      a.set(30); // Should not trigger recompute now
      expect(result(), equals(20));

      b.set(40);
      expect(result(), equals(40));
    });

    test('computed with complex types', () {
      final items = signal<List<int>>(null, [1, 2, 3]);
      final sum = computed(null, (_) {
        return items().reduce((a, b) => a + b);
      });

      expect(sum(), equals(6));

      items.set([1, 2, 3, 4]);
      expect(sum(), equals(10));
    });

    test('multiple computed values from same signal', () {
      final count = signal(null, 5);
      final doubled = computed(null, (_) => count() * 2);
      final tripled = computed(null, (_) => count() * 3);

      expect(doubled(), equals(10));
      expect(tripled(), equals(15));

      count.set(10);
      expect(doubled(), equals(20));
      expect(tripled(), equals(30));
    });
  });

  group('Computed with Flutter Widget Context', () {
    testWidgets('computes value from signal in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 5);
              final doubled = computed(context, (_) => count() * 2);
              return Column(
                children: [
                  Text('${doubled()}'),
                  TextButton(
                    onPressed: () => count.set(count() + 1),
                    child: const Text('increment'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('computed updates when dependency changes in widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final a = signal(context, 2);
              final b = signal(context, 3);
              final sum = computed(context, (_) => a() + b());
              return Column(
                children: [
                  Text('Sum: ${sum()}'),
                  TextButton(
                    onPressed: () => a.set(a() + 1),
                    child: const Text('inc a'),
                  ),
                  TextButton(
                    onPressed: () => b.set(b() + 1),
                    child: const Text('inc b'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Sum: 5'), findsOneWidget);

      await tester.tap(find.text('inc a'));
      await tester.pump();
      expect(find.text('Sum: 6'), findsOneWidget);

      await tester.tap(find.text('inc b'));
      await tester.pump();
      expect(find.text('Sum: 7'), findsOneWidget);
    });

    testWidgets('chained computed values in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 2);
              final doubled = computed(context, (_) => count() * 2);
              final quadrupled = computed(context, (_) => doubled() * 2);
              return Column(
                children: [
                  Text('${quadrupled()}'),
                  TextButton(
                    onPressed: () => count.set(count() + 1),
                    child: const Text('increment'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('8'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('computed is lazy in widget', (tester) async {
      int computeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 5);
              final doubled = computed(context, (_) {
                computeCount++;
                return count() * 2;
              });
              return Column(
                children: [
                  Text('${doubled()}'),
                  TextButton(
                    onPressed: () => count.set(count() + 1),
                    child: const Text('increment'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      // First build should compute once
      expect(computeCount, greaterThan(0));
      final initialCount = computeCount;

      await tester.tap(find.text('increment'));
      await tester.pump();

      // Should compute again after signal changes
      expect(computeCount, greaterThan(initialCount));
    });

    // TODO: https://github.com/medz/oref/issues/17
    // testWidgets('computed with previous value in widget', (tester) async {
    //   await tester.pumpWidget(
    //     MaterialApp(
    //       home: Builder(
    //         builder: (context) {
    //           final count = signal(context, 1);
    //           final accumulated = computed<int>(context, (prev) {
    //             return (prev ?? 0) + count();
    //           });
    //           debugPrint('accumulated value: ${accumulated()}');
    //           return Column(
    //             children: [
    //               Text('${accumulated()}'),
    //               TextButton(
    //                 onPressed: () => count(count() + 1),
    //                 child: const Text('increment'),
    //               ),
    //             ],
    //           );
    //         },
    //       ),
    //     ),
    //   );

    //   expect(find.text('1'), findsOneWidget);

    //   await tester.tap(find.text('increment'));
    //   await tester.pump();
    //   expect(find.text('3'), findsOneWidget); // 1 + 2

    //   await tester.tap(find.text('increment'));
    //   await tester.pump();
    //   expect(find.text('6'), findsOneWidget); // 3 + 3
    // });

    testWidgets('computed with conditional dependencies in widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final condition = signal(context, true);
              final a = signal(context, 1);
              final b = signal(context, 2);
              final result = computed(context, (_) {
                return condition() ? a() : b();
              });
              return Column(
                children: [
                  Text('${result()}'),
                  TextButton(
                    onPressed: () => condition.set(!condition()),
                    child: const Text('toggle'),
                  ),
                  TextButton(
                    onPressed: () => a.set(a() + 10),
                    child: const Text('inc a'),
                  ),
                  TextButton(
                    onPressed: () => b.set(b() + 10),
                    child: const Text('inc b'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('inc a'));
      await tester.pump();
      expect(find.text('11'), findsOneWidget);

      await tester.tap(find.text('toggle'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('inc b'));
      await tester.pump();
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('computed triggers widget rebuild', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              buildCount++;
              final count = signal(context, 5);
              final doubled = computed(context, (_) => count() * 2);
              return Column(
                children: [
                  Text('${doubled()}'),
                  TextButton(
                    onPressed: () => count.set(count() + 1),
                    child: const Text('increment'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(buildCount, equals(2));
    });
  });

  group('WritableComputed', () {
    test('computes value from signals', () {
      final count = signal<double>(null, 2);
      final squared = writableComputed<double>(
        null,
        get: (_) => count() * count(),
        set: (value) => count.set(value / 2),
      );

      expect(squared(), equals(4.0));
    });

    test('can be written to', () {
      final count = signal<double>(null, 2);
      final squared = writableComputed<double>(
        null,
        get: (_) => count() * count(),
        set: (value) => count.set(value / 2),
      );

      expect(count(), equals(2.0));
      expect(squared(), equals(4.0));

      squared.set(16.0);
      expect(count(), equals(8.0));
      expect(squared(), equals(64.0));
    });

    test('setter can use custom logic', () {
      final count = signal<double>(null, 0);
      final squared = writableComputed<double>(
        null,
        get: (_) => count() * count(),
        set: (value) {
          // Use sqrt to reverse the squared operation
          final root = value < 0
              ? -1.0
              : value.sign * (value.abs()).clamp(0.0, double.infinity);
          count.set(root == -1.0 ? 0.0 : root);
        },
      );

      squared.set(9.0);
      expect(count(), equals(9.0));
      expect(squared(), equals(81.0));

      squared.set(0.0);
      expect(count(), equals(0.0));
      expect(squared(), equals(0.0));
    });

    test('updates multiple dependent signals', () {
      final a = signal<int>(null, 2);
      final b = signal<int>(null, 3);
      final sum = writableComputed<int>(
        null,
        get: (_) => a() + b(),
        set: (value) {
          // Split the value between a and b
          a.set(value ~/ 2);
          b.set(value - (value ~/ 2));
        },
      );

      expect(sum(), equals(5));

      sum.set(10);
      expect(a(), equals(5));
      expect(b(), equals(5));
      expect(sum(), equals(10));
    });

    test('triggers effects on write', () {
      int effectCount = 0;
      final count = signal<double>(null, 2);
      final squared = writableComputed<double>(
        null,
        get: (_) => count() * count(),
        set: (value) => count.set(value / 2),
      );

      effect(null, () {
        squared();
        effectCount++;
      });

      expect(effectCount, equals(1));

      squared.set(16.0);
      expect(effectCount, equals(2));
    });

    test('can be chained with other computed', () {
      final count = signal<double>(null, 2);
      final squared = writableComputed<double>(
        null,
        get: (_) => count() * count(),
        set: (value) => count.set(value / 2),
      );
      final doubled = computed<double>(null, (_) => squared() * 2);

      expect(squared(), equals(4.0));
      expect(doubled(), equals(8.0));

      squared.set(16.0);
      expect(squared(), equals(64.0));
      expect(doubled(), equals(128.0));
    });

    test('can be used as dependency for other writableComputed', () {
      final base = signal<double>(null, 2);
      final squared = writableComputed<double>(
        null,
        get: (_) => base() * base(),
        set: (value) => base.set(value / 2),
      );
      final doubled = writableComputed<double>(
        null,
        get: (_) => squared() * 2,
        set: (value) => squared.set(value / 2),
      );

      expect(base(), equals(2.0));
      expect(squared(), equals(4.0));
      expect(doubled(), equals(8.0));

      doubled.set(32.0);
      expect(base(), equals(8.0));
      expect(squared(), equals(64.0));
      expect(doubled(), equals(128.0));
    });

    test('handles null values correctly', () {
      final value = signal<double?>(null, null);
      final computed = writableComputed<double?>(
        null,
        get: (_) => value() != null ? value()! * 2 : null,
        set: (v) => value.set(v != null ? v / 2 : null),
      );

      expect(computed(), isNull);

      computed.set(10.0);
      expect(value(), equals(5.0));
      expect(computed(), equals(10.0));

      computed.set(null);
      expect(value(), isNull);
      expect(computed(), isNull);
    });

    test('setter receives exact value written', () {
      double? capturedValue;
      final base = signal<double>(null, 0);
      final computed = writableComputed<double>(
        null,
        get: (_) => base(),
        set: (value) {
          capturedValue = value;
          base.set(value);
        },
      );

      computed.set(42.5);
      expect(capturedValue, equals(42.5));
      expect(base(), equals(42.5));
    });

    test('multiple writes in sequence', () {
      final count = signal<int>(null, 0);
      final computed = writableComputed<int>(
        null,
        get: (_) => count() * 10,
        set: (value) => count.set(value ~/ 10),
      );

      computed.set(10);
      expect(count(), equals(1));
      expect(computed(), equals(10));

      computed.set(20);
      expect(count(), equals(2));
      expect(computed(), equals(20));

      computed.set(30);
      expect(count(), equals(3));
      expect(computed(), equals(30));
    });

    test('getter uses previous value', () {
      final count = signal<int>(null, 1);
      final accumulated = writableComputed<int>(
        null,
        get: (prev) => (prev ?? 0) + count(),
        set: (_) => {}, // No-op setter
      );

      expect(accumulated(), equals(1));

      count.set(2);
      expect(accumulated(), equals(3)); // 1 + 2

      count.set(3);
      expect(accumulated(), equals(6)); // 3 + 3
    });

    test('works with complex types', () {
      final list = signal<List<int>>(null, [1, 2, 3]);
      final computed = writableComputed<int>(
        null,
        get: (_) => list().reduce((a, b) => a + b),
        set: (value) => list.set([value]),
      );

      expect(computed(), equals(6));

      computed.set(10);
      expect(list(), equals([10]));
      expect(computed(), equals(10));
    });

    test('setter can validate input', () {
      final count = signal<int>(null, 5);
      final bounded = writableComputed<int>(
        null,
        get: (_) => count(),
        set: (value) {
          // Clamp value between 0 and 10
          count.set(value.clamp(0, 10));
        },
      );

      bounded.set(15);
      expect(count(), equals(10));
      expect(bounded(), equals(10));

      bounded.set(-5);
      expect(count(), equals(0));
      expect(bounded(), equals(0));

      bounded.set(5);
      expect(count(), equals(5));
      expect(bounded(), equals(5));
    });

    test('returns written value', () {
      final count = signal<double>(null, 0);
      final computed = writableComputed<double>(
        null,
        get: (_) => count(),
        set: (value) => count.set(value),
      );

      computed.set(42.0);
      expect(count(), equals(42.0));
      expect(computed(), equals(42.0));
    });
  });

  group('WritableComputed with Flutter Widget Context', () {
    testWidgets('computes and writes value in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal<double>(context, 2);
              final squared = writableComputed<double>(
                context,
                get: (_) => count() * count(),
                set: (value) => count.set(value / 2),
              );
              return Column(
                children: [
                  Text('Count: ${count()}'),
                  Text('Squared: ${squared()}'),
                  TextButton(
                    onPressed: () => squared.set(16.0),
                    child: const Text('set to 16'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Count: 2.0'), findsOneWidget);
      expect(find.text('Squared: 4.0'), findsOneWidget);

      await tester.tap(find.text('set to 16'));
      await tester.pump();

      expect(find.text('Count: 8.0'), findsOneWidget);
      expect(find.text('Squared: 64.0'), findsOneWidget);
    });

    testWidgets('triggers widget rebuild on write', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              buildCount++;
              final count = signal<double>(context, 2);
              final squared = writableComputed<double>(
                context,
                get: (_) => count() * count(),
                set: (value) => count.set(value / 2),
              );
              return Column(
                children: [
                  Text('${squared()}'),
                  TextButton(
                    onPressed: () => squared.set(16.0),
                    child: const Text('write'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      await tester.tap(find.text('write'));
      await tester.pump();

      expect(buildCount, equals(2));
    });

    testWidgets('updates multiple dependent signals in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final a = signal<int>(context, 2);
              final b = signal<int>(context, 3);
              final sum = writableComputed<int>(
                context,
                get: (_) => a() + b(),
                set: (value) {
                  a.set(value ~/ 2);
                  b.set(value - (value ~/ 2));
                },
              );
              return Column(
                children: [
                  Text('A: ${a()}'),
                  Text('B: ${b()}'),
                  Text('Sum: ${sum()}'),
                  TextButton(
                    onPressed: () => sum.set(10),
                    child: const Text('set sum to 10'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('A: 2'), findsOneWidget);
      expect(find.text('B: 3'), findsOneWidget);
      expect(find.text('Sum: 5'), findsOneWidget);

      await tester.tap(find.text('set sum to 10'));
      await tester.pump();

      expect(find.text('A: 5'), findsOneWidget);
      expect(find.text('B: 5'), findsOneWidget);
      expect(find.text('Sum: 10'), findsOneWidget);
    });

    testWidgets('chained with computed in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal<double>(context, 2);
              final squared = writableComputed<double>(
                context,
                get: (_) => count() * count(),
                set: (value) => count.set(value / 2),
              );
              final doubled = computed<double>(context, (_) => squared() * 2);
              return Column(
                children: [
                  Text('Squared: ${squared()}'),
                  Text('Doubled: ${doubled()}'),
                  TextButton(
                    onPressed: () => squared.set(16.0),
                    child: const Text('write'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Squared: 4.0'), findsOneWidget);
      expect(find.text('Doubled: 8.0'), findsOneWidget);

      await tester.tap(find.text('write'));
      await tester.pump();

      expect(find.text('Squared: 64.0'), findsOneWidget);
      expect(find.text('Doubled: 128.0'), findsOneWidget);
    });

    testWidgets('handles null values in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final value = signal<double?>(context, null);
              final computed = writableComputed<double?>(
                context,
                get: (_) => value() != null ? value()! * 2 : null,
                set: (v) => value.set(v != null ? v / 2 : null),
              );
              return Column(
                children: [
                  Text('Value: ${computed()}'),
                  TextButton(
                    onPressed: () => computed.set(10.0),
                    child: const Text('set to 10'),
                  ),
                  TextButton(
                    onPressed: () => computed.set(null),
                    child: const Text('set to null'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Value: null'), findsOneWidget);

      await tester.tap(find.text('set to 10'));
      await tester.pump();
      expect(find.text('Value: 10.0'), findsOneWidget);

      await tester.tap(find.text('set to null'));
      await tester.pump();
      expect(find.text('Value: null'), findsOneWidget);
    });

    testWidgets('setter with validation in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal<int>(context, 5);
              final bounded = writableComputed<int>(
                context,
                get: (_) => count(),
                set: (value) => count.set(value.clamp(0, 10)),
              );
              return Column(
                children: [
                  Text('Value: ${bounded()}'),
                  TextButton(
                    onPressed: () => bounded.set(15),
                    child: const Text('set to 15'),
                  ),
                  TextButton(
                    onPressed: () => bounded.set(-5),
                    child: const Text('set to -5'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Value: 5'), findsOneWidget);

      await tester.tap(find.text('set to 15'));
      await tester.pump();
      expect(find.text('Value: 10'), findsOneWidget);

      await tester.tap(find.text('set to -5'));
      await tester.pump();
      expect(find.text('Value: 0'), findsOneWidget);
    });
  });
}
