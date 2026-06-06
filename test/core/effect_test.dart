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
      expect(cleanupCount, equals(2)); // Cleanup runs before dispose
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

  group('Effect auto-dispose behavior', () {
    test('failed effect setup does not leave a live subscription behind', () {
      final source = signal(null, 0);
      int runs = 0;

      expect(
        () => effect(null, () {
          runs++;
          source();
          throw StateError('setup failed');
        }),
        throwsStateError,
      );

      expect(runs, 1);
      // If cleanup worked, changing source should not re-run the broken effect.
      expect(() => source.set(1), returnsNormally);
      expect(runs, 1);
    });

    test(
      'failed effect scope setup disposes child effects created before throw',
      () {
        final source = signal(null, 0);
        int childRuns = 0;

        expect(
          () => effectScope(null, () {
            effect(null, () {
              childRuns++;
              source();
            });
            throw StateError('scope setup failed');
          }),
          throwsStateError,
        );

        expect(childRuns, 1);
        // If cleanup worked, changing source should not re-run the child effect.
        source.set(1);
        expect(childRuns, 1);
      },
    );

    test(
      'stopped effect does not subscribe to signals read later in the same run',
      () {
        final rerun = signal(null, 0);
        final readAfterStop = signal(null, 0);
        Effect? stop;
        bool stopDuringRun = false;
        int runs = 0;

        stop = effect(null, () {
          runs++;
          rerun();
          if (stopDuringRun) {
            stop!();
            // Reading a signal after stopping should not create a subscription.
            readAfterStop();
          }
        });

        expect(runs, 1);

        stopDuringRun = true;
        rerun.set(1);

        // The effect should have run a second time (before stopping itself).
        expect(runs, 2);
        // readAfterStop should NOT have a subscription from the stopped effect.
        expect(() => readAfterStop.set(1), returnsNormally);
        // No further runs.
        expect(runs, 2);
      },
    );

    test(
      'after stop(), activeSub persists and re-links signals read post-stop',
      () {
        // Verifies: when an effect calls its own disposer in the callback,
        // activeSub is still the effect until _wrapEffectCallback returns.
        // In alien_signals 2.3.1, SignalNode.get() unconditionally links to
        // activeSub, so any signal read after stop() re-links the disposed
        // effect. The effect won't re-execute (run() guard prevents it), but
        // the stale link causes unnecessary propagation on every signal change.
        final trigger = signal(null, 0);
        final postStop = signal(null, 0);
        Effect? stopper;
        bool shouldStop = false;
        int runs = 0;

        stopper = effect(null, () {
          runs++;
          trigger();
          if (shouldStop) {
            stopper!();
            postStop(); // re-links via activeSub — unnecessary propagation
          }
        });

        expect(runs, 1);

        shouldStop = true;
        trigger.set(1);
        expect(runs, 2);

        // postStop was re-linked. Its changes trigger useless propagation
        // through the stopped effect, but never cause re-execution.
        postStop.set(1);
        expect(runs, 2);
        postStop.set(2);
        expect(runs, 2);
      },
    );
  });

  group('Effect auto-dispose with Flutter Widget Context', () {
    testWidgets('failed effect setup in widget does not leave subscription',
        (tester) async {
      final source = signal(null, 0);
      int runs = 0;
      bool caught = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              if (!caught) {
                try {
                  effect(context, () {
                    runs++;
                    source();
                    throw StateError('setup failed');
                  });
                } on StateError {
                  caught = true;
                }
              }
              return const SizedBox();
            },
          ),
        ),
      );

      expect(runs, 1);
      expect(caught, isTrue);

      // Trigger the signal — the broken effect should not re-run.
      source.set(1);
      await tester.pump();

      expect(runs, 1);
    });

    testWidgets(
        'failed effect scope in widget disposes child effects created before throw',
        (tester) async {
      final source = signal(null, 0);
      int childRuns = 0;
      bool caught = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              if (!caught) {
                try {
                  effectScope(context, () {
                    effect(context, () {
                      childRuns++;
                      source();
                    });
                    throw StateError('scope setup failed');
                  });
                } on StateError {
                  caught = true;
                }
              }
              return const SizedBox();
            },
          ),
        ),
      );

      expect(childRuns, 1);
      expect(caught, isTrue);

      // The child effect should be disposed — signal change should not re-run it.
      source.set(1);
      await tester.pump();

      expect(childRuns, 1);
    });
  });
}
