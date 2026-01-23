import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Effect', () {
    test('runs immediately on creation', () {
      int runCount = 0;
      effect(null, () {
        runCount++;
      });

      expect(runCount, equals(1));
    });

    test('tracks signal dependencies', () {
      int runCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        runCount++;
      });

      expect(runCount, equals(1));

      count.set(1);
      expect(runCount, equals(2));

      count.set(2);
      expect(runCount, equals(3));
    });

    test('stops when disposed', () {
      int runCount = 0;
      final count = signal(null, 0);

      final dispose = effect(null, () {
        count();
        runCount++;
      });

      expect(runCount, equals(1));

      count.set(1);
      expect(runCount, equals(2));

      dispose();

      count.set(2);
      expect(runCount, equals(2)); // Should not run after dispose
    });

    test('tracks multiple signals', () {
      int runCount = 0;
      final a = signal(null, 0);
      final b = signal(null, 0);

      effect(null, () {
        a();
        b();
        runCount++;
      });

      expect(runCount, equals(1));

      a.set(1);
      expect(runCount, equals(2));

      b.set(1);
      expect(runCount, equals(3));
    });

    test('tracks computed values', () {
      int runCount = 0;
      final count = signal(null, 5);
      final doubled = computed(null, (_) => count() * 2);

      effect(null, () {
        doubled();
        runCount++;
      });

      expect(runCount, equals(1));

      count.set(10);
      expect(runCount, equals(2));
    });

    test('onEffectDispose callback runs on dispose', () {
      bool disposed = false;
      final count = signal(null, 0);

      final dispose = effect(null, () {
        count();
        onEffectDispose(() {
          disposed = true;
        });
      });

      expect(disposed, isFalse);

      dispose();
      expect(disposed, isTrue);
    });

    test('onEffectCleanup runs before re-execution', () {
      int cleanupCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        onEffectCleanup(() {
          cleanupCount++;
        });
      });

      expect(cleanupCount, equals(0));

      count.set(1);
      expect(cleanupCount, equals(1));

      count.set(2);
      expect(cleanupCount, equals(2));
    });

    test('onEffectCleanup and onEffectDispose work together', () {
      int cleanupCount = 0;
      bool disposed = false;
      final count = signal(null, 0);

      final dispose = effect(null, () {
        count();
        onEffectCleanup(() {
          cleanupCount++;
        });
        onEffectDispose(() {
          disposed = true;
        });
      });

      expect(cleanupCount, equals(0));
      expect(disposed, isFalse);

      count.set(1);
      expect(cleanupCount, equals(1));
      expect(disposed, isFalse);

      dispose();
      expect(cleanupCount, equals(1)); // Cleanup doesn't run on dispose
      expect(disposed, isTrue);
    });

    test('conditional dependencies', () {
      int runCount = 0;
      final condition = signal(null, true);
      final a = signal(null, 1);
      final b = signal(null, 2);

      effect(null, () {
        condition() ? a() : b();
        runCount++;
      });

      expect(runCount, equals(1));

      a.set(10);
      expect(runCount, equals(2));

      b.set(20); // Should not trigger
      expect(runCount, equals(2));

      condition.set(false);
      expect(runCount, equals(3));

      a.set(30); // Should not trigger now
      expect(runCount, equals(3));

      b.set(40);
      expect(runCount, equals(4));
    });

    test('nested effects', () {
      int outerRuns = 0;
      int innerRuns = 0;
      final outer = signal(null, 0);
      final inner = signal(null, 0);

      effect(null, () {
        outer();
        outerRuns++;

        effect(null, () {
          inner();
          innerRuns++;
        });
      });

      expect(outerRuns, equals(1));
      expect(innerRuns, equals(1));

      inner.set(1);
      expect(outerRuns, equals(1));
      expect(innerRuns, equals(2));

      outer.set(1);
      expect(outerRuns, equals(2));
      expect(innerRuns, equals(3)); // New inner effect created
    });

    test('effect with detach option', () {
      int parentRuns = 0;
      int childRuns = 0;
      final parent = signal(null, 0);
      final child = signal(null, 0);

      effect(null, () {
        parent();
        parentRuns++;

        effect(null, () {
          child();
          childRuns++;
        }, detach: true);
      });

      expect(parentRuns, equals(1));
      expect(childRuns, equals(1));

      child.set(1);
      expect(childRuns, equals(2));

      parent.set(1);
      expect(parentRuns, equals(2));
      expect(childRuns, equals(3)); // New detached effect created
    });

    test('multiple effects on same signal', () {
      int effect1Count = 0;
      int effect2Count = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        effect1Count++;
      });

      effect(null, () {
        count();
        effect2Count++;
      });

      expect(effect1Count, equals(1));
      expect(effect2Count, equals(1));

      count.set(1);
      expect(effect1Count, equals(2));
      expect(effect2Count, equals(2));
    });

    test('effect with side effects', () {
      final values = <int>[];
      final count = signal(null, 0);

      effect(null, () {
        values.add(count());
      });

      expect(values, equals([0]));

      count.set(1);
      expect(values, equals([0, 1]));

      count.set(2);
      expect(values, equals([0, 1, 2]));
    });
  });

  group('Effect with Flutter Widget Context', () {
    testWidgets('effect tracks signal in widget', (tester) async {
      final effectValues = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 0);
              effect(context, () {
                effectValues.add(count());
              });
              return Column(
                children: [
                  Text('${count()}'),
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

      // Effect should run initially
      expect(effectValues.isNotEmpty, isTrue);
      final initialLength = effectValues.length;

      await tester.tap(find.text('increment'));
      await tester.pump();

      // Effect should run again after signal changes
      expect(effectValues.length, greaterThan(initialLength));
    });

    testWidgets('effect with multiple signals in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final a = signal(context, 0);
              final b = signal(context, 0);
              final sum = signal(context, 0);

              effect(context, () {
                sum.set(a() + b());
              });

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

      expect(find.text('Sum: 0'), findsOneWidget);

      await tester.tap(find.text('inc a'));
      await tester.pump();
      expect(find.text('Sum: 1'), findsOneWidget);

      await tester.tap(find.text('inc b'));
      await tester.pump();
      expect(find.text('Sum: 2'), findsOneWidget);
    });

    testWidgets('effect with computed value in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 5);
              final doubled = computed(context, (_) => count() * 2);
              final result = signal(context, 0);

              effect(context, () {
                result.set(doubled());
              });

              return Column(
                children: [
                  Text('Result: ${result()}'),
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

      expect(find.text('Result: 10'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(find.text('Result: 12'), findsOneWidget);
    });

    testWidgets('effect triggers widget rebuild', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              buildCount++;
              final count = signal(context, 0);
              final output = signal(context, 0);

              effect(context, () {
                output.set(count());
              });

              return Column(
                children: [
                  Text('${output()}'),
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

    testWidgets('effect with conditional dependencies in widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final condition = signal(context, true);
              final a = signal(context, 1);
              final b = signal(context, 2);
              final result = signal(context, 0);

              effect(context, () {
                result.set(condition() ? a() : b());
              });

              return Column(
                children: [
                  Text('Result: ${result()}'),
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

      expect(find.text('Result: 1'), findsOneWidget);

      await tester.tap(find.text('inc a'));
      await tester.pump();
      expect(find.text('Result: 11'), findsOneWidget);

      await tester.tap(find.text('toggle'));
      await tester.pump();
      expect(find.text('Result: 2'), findsOneWidget);

      await tester.tap(find.text('inc b'));
      await tester.pump();
      expect(find.text('Result: 12'), findsOneWidget);
    });

    testWidgets('effect with side effects in widget', (tester) async {
      final values = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 0);

              effect(context, () {
                values.add(count());
              });

              return Column(
                children: [
                  Text('${count()}'),
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

      // Should have initial value
      expect(values.isNotEmpty, isTrue);
      final initialValue = values.first;
      expect(initialValue, equals(0));

      await tester.tap(find.text('increment'));
      await tester.pump();

      // Should have new value
      expect(values.last, equals(1));
    });

    testWidgets('multiple effects on same signal in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 0);
              final output1 = signal(context, 0);
              final output2 = signal(context, 0);

              effect(context, () {
                output1.set(count() * 2);
              });

              effect(context, () {
                output2.set(count() * 3);
              });

              return Column(
                children: [
                  Text('Output1: ${output1()}'),
                  Text('Output2: ${output2()}'),
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

      expect(find.text('Output1: 0'), findsOneWidget);
      expect(find.text('Output2: 0'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(find.text('Output1: 2'), findsOneWidget);
      expect(find.text('Output2: 3'), findsOneWidget);
    });
  });
}
