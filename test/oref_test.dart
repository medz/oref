import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('Oref Tests', () {
    testWidgets('useSignal creates reactive state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                final count = useSignal(context, 0);

                return Column(
                  children: [
                    Text('Count: ${count()}'),
                    TextButton(
                      onPressed: () => count(count() + 1),
                      child: const Text('Increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('useComputed derives reactive values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                final count = useSignal(context, 2);
                final doubled = useComputed(context, (_) => count() * 2);

                return Column(
                  children: [
                    Text('Count: ${count()}'),
                    Text('Doubled: ${doubled()}'),
                    TextButton(
                      onPressed: () => count(count() + 1),
                      child: const Text('Increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 2'), findsOneWidget);
      expect(find.text('Doubled: 4'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();

      expect(find.text('Count: 3'), findsOneWidget);
      expect(find.text('Doubled: 6'), findsOneWidget);
    });

    testWidgets('useEffect runs on dependency changes', (tester) async {
      final log = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                final message = useSignal(context, 'Hello');

                useEffect(context, () {
                  log.add(message());
                });

                return Column(
                  children: [
                    Text(message()),
                    TextButton(
                      onPressed: () => message('World'),
                      child: const Text('Change'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(log, contains('Hello'));

      await tester.tap(find.text('Change'));
      await tester.pump();

      expect(log, contains('World'));
      expect(find.text('World'), findsOneWidget);
    });

    testWidgets('ref makes widget parameters reactive', (tester) async {
      Widget testWidget(String value) {
        return MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                final valueRef = ref(context, value);
                return Text(valueRef());
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(testWidget('First'));
      expect(find.text('First'), findsOneWidget);

      await tester.pumpWidget(testWidget('Second'));
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('useEffectScope manages grouped effects', (tester) async {
      final log = <String>[];
      VoidCallback? stopEffects;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (context) {
                final value = useSignal(context, 'A');

                stopEffects = useEffectScope(context, () {
                  useEffect(context, () {
                    log.add('Effect 1: ${value()}');
                  });

                  useEffect(context, () {
                    log.add('Effect 2: ${value()}');
                  });
                });

                return Column(
                  children: [
                    Text(value()),
                    TextButton(
                      onPressed: () => value('B'),
                      child: const Text('Update'),
                    ),
                    TextButton(
                      onPressed: () {
                        stopEffects?.call();
                        value('C');
                      },
                      child: const Text('Stop and Update'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Both effects should run initially
      expect(log.where((s) => s.contains('A')).length, 2);

      log.clear();
      await tester.tap(find.text('Update'));
      await tester.pump();

      // Both effects should run on update
      expect(log.where((s) => s.contains('B')).length, 2);

      log.clear();
      await tester.tap(find.text('Stop and Update'));
      await tester.pump();

      expect(log.isEmpty, true);
      // expect(find.text('C'), notFind);
    });

    test('global signal works outside widgets', () {
      final globalCount = createGlobalSignal(0);

      expect(globalCount(), 0);

      globalCount(42);
      expect(globalCount(), 42);
    });

    test('global computed updates with dependencies', () {
      final count = createGlobalSignal(5);
      final doubled = createGlobalComputed((_) => count() * 2);

      expect(doubled(), 10);

      count(7);
      expect(doubled(), 14);
    });

    test('global effect triggers on changes', () {
      final log = <int>[];
      final value = createGlobalSignal(1);

      final stop = createGlobalEffect(() {
        log.add(value());
      });

      expect(log, [1]);

      value(2);
      expect(log, [1, 2]);

      value(3);
      expect(log, [1, 2, 3]);

      stop();
      value(4);
      expect(log, [1, 2, 3]); // No change after stopping
    });
  });
}
