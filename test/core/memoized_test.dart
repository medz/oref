import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('Memoized', () {
    testWidgets('memoizes value in widget', (tester) async {
      int createCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final value = useMemoized(context, () {
                createCount++;
                return 42;
              });

              return Text('$value');
            },
          ),
        ),
      );

      expect(createCount, equals(1));
      expect(find.text('42'), findsOneWidget);

      // Rebuild should not create new value
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final value = useMemoized(context, () {
                createCount++;
                return 42;
              });

              return Text('$value');
            },
          ),
        ),
      );

      expect(createCount, equals(1)); // Should still be 1
    });

    testWidgets('creates different values for different types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final intValue = useMemoized<int>(context, () => 42);
              final stringValue = useMemoized<String>(context, () => 'hello');

              return Column(
                children: [
                  Text('$intValue'),
                  Text(stringValue),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('memoizes signal creation', (tester) async {
      int signalCreateCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = useMemoized(context, () {
                signalCreateCount++;
                return signal(null, 0);
              });

              return Column(
                children: [
                  Text('${count()}'),
                  TextButton(
                    child: const Text('increment'),
                    onPressed: () => count(count() + 1),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(signalCreateCount, equals(1));
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(signalCreateCount, equals(1)); // Should not recreate
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('memoizes computed values', (tester) async {
      int computedCreateCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 5);
              final doubled = useMemoized(context, () {
                computedCreateCount++;
                return computed(null, (_) => count() * 2);
              });

              return Text('${doubled()}');
            },
          ),
        ),
      );

      expect(computedCreateCount, equals(1));
      expect(find.text('10'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 5);
              final doubled = useMemoized(context, () {
                computedCreateCount++;
                return computed(null, (_) => count() * 2);
              });

              return Text('${doubled()}');
            },
          ),
        ),
      );

      expect(computedCreateCount, equals(1)); // Should not recreate
    });

    testWidgets('memoizes complex objects', (tester) async {
      int createCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final list = useMemoized(context, () {
                createCount++;
                return <int>[1, 2, 3];
              });

              return Text('${list.length}');
            },
          ),
        ),
      );

      expect(createCount, equals(1));
      expect(find.text('3'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final list = useMemoized(context, () {
                createCount++;
                return <int>[1, 2, 3];
              });

              return Text('${list.length}');
            },
          ),
        ),
      );

      expect(createCount, equals(1));
    });

    testWidgets('multiple memoized values in same widget', (tester) async {
      int count1Creates = 0;
      int count2Creates = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count1 = useMemoized(context, () {
                count1Creates++;
                return signal(null, 0);
              });
              final count2 = useMemoized(context, () {
                count2Creates++;
                return signal(null, 100);
              });

              return Column(
                children: [
                  Text('count1: ${count1()}'),
                  Text('count2: ${count2()}'),
                ],
              );
            },
          ),
        ),
      );

      expect(count1Creates, equals(1));
      expect(count2Creates, equals(1));
      expect(find.text('count1: 0'), findsOneWidget);
      expect(find.text('count2: 100'), findsOneWidget);
    });

    testWidgets('resetMemoizedFor resets traversal pointer', (tester) async {
      int createCount = 0;
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              savedContext = context;
              final value = useMemoized(context, () {
                createCount++;
                return 42;
              });

              return Text('$value');
            },
          ),
        ),
      );

      expect(createCount, equals(1));

      resetMemoizedFor(savedContext);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final value = useMemoized(context, () {
                createCount++;
                return 42;
              });

              return Text('$value');
            },
          ),
        ),
      );

      expect(createCount, equals(1)); // Should reuse existing memoized value
    });

    testWidgets('memoizes reactive collections', (tester) async {
      int listCreateCount = 0;
      int mapCreateCount = 0;
      int setCreateCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final list = useMemoized(context, () {
                listCreateCount++;
                return ReactiveList<int>([1, 2, 3]);
              });
              final map = useMemoized(context, () {
                mapCreateCount++;
                return ReactiveMap<String, int>({'a': 1});
              });
              final set = useMemoized(context, () {
                setCreateCount++;
                return ReactiveSet<int>([1, 2, 3]);
              });

              return Column(
                children: [
                  Text('list: ${list.length}'),
                  Text('map: ${map.length}'),
                  Text('set: ${set.length}'),
                ],
              );
            },
          ),
        ),
      );

      expect(listCreateCount, equals(1));
      expect(mapCreateCount, equals(1));
      expect(setCreateCount, equals(1));

      await tester.pump();

      expect(listCreateCount, equals(1));
      expect(mapCreateCount, equals(1));
      expect(setCreateCount, equals(1));
    });

    testWidgets('works with stateful widgets', (tester) async {
      int createCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              final value = useMemoized(context, () {
                createCount++;
                return 42;
              });

              return Column(
                children: [
                  Text('$value'),
                  TextButton(
                    child: const Text('rebuild'),
                    onPressed: () => setState(() {}),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(createCount, equals(1));

      await tester.tap(find.text('rebuild'));
      await tester.pump();

      expect(createCount, equals(1)); // Should not recreate
    });

    testWidgets('memoized value persists across rebuilds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 0);
              return Column(
                children: [
                  Text('${count()}'),
                  TextButton(
                    child: const Text('increment'),
                    onPressed: () => count(count() + 1),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('different contexts have separate memoized values', (tester) async {
      int globalCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Builder(
                builder: (context) {
                  final value = useMemoized(context, () {
                    return ++globalCount;
                  });
                  return Text('first: $value');
                },
              ),
              Builder(
                builder: (context) {
                  final value = useMemoized(context, () {
                    return ++globalCount;
                  });
                  return Text('second: $value');
                },
              ),
            ],
          ),
        ),
      );

      expect(find.text('first: 1'), findsOneWidget);
      expect(find.text('second: 2'), findsOneWidget);
      expect(globalCount, equals(2));
    });
  });
}
