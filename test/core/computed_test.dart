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
                    onPressed: () => count(count() + 1),
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

    testWidgets('computed updates when dependency changes in widget',
        (tester) async {
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
                    onPressed: () => a(a() + 1),
                    child: const Text('inc a'),
                  ),
                  TextButton(
                    onPressed: () => b(b() + 1),
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
                    onPressed: () => count(count() + 1),
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
                    onPressed: () => count(count() + 1),
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

    testWidgets('computed with previous value in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 1);
              final accumulated = computed<int>(context, (prev) {
                return (prev ?? 0) + count();
              });
              return Column(
                children: [
                  Text('${accumulated()}'),
                  TextButton(
                    onPressed: () => count(count() + 1),
                    child: const Text('increment'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();
      expect(find.text('3'), findsOneWidget); // 1 + 2

      await tester.tap(find.text('increment'));
      await tester.pump();
      expect(find.text('6'), findsOneWidget); // 3 + 3
    });

    testWidgets('computed with conditional dependencies in widget',
        (tester) async {
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
                    onPressed: () => condition(!condition()),
                    child: const Text('toggle'),
                  ),
                  TextButton(
                    onPressed: () => a(a() + 10),
                    child: const Text('inc a'),
                  ),
                  TextButton(
                    onPressed: () => b(b() + 10),
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
                    onPressed: () => count(count() + 1),
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
}
