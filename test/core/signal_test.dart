import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Signal with Flutter Widget Context', () {
    testWidgets('creates signal with widget context', (tester) async {
      int? signalValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 42);
              signalValue = count();
              return Text('$signalValue');
            },
          ),
        ),
      );

      expect(signalValue, equals(42));
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('updates signal value in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, 0);
              return Column(
                children: [
                  Text('${count()}'),
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

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('signal triggers widget rebuild', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              buildCount++;
              final count = signal(context, 0);
              return Column(
                children: [
                  Text('${count()}'),
                  TextButton(
                    onPressed: () => count(count() + 1),
                    child: const Text('tap'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      await tester.tap(find.text('tap'));
      await tester.pump();

      expect(buildCount, equals(2));
    });

    testWidgets('multiple signals in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count1 = signal(context, 0);
              final count2 = signal(context, 10);
              return Column(
                children: [
                  Text('Sum: ${count1() + count2()}'),
                  TextButton(
                    onPressed: () => count1(count1() + 1),
                    child: const Text('increment1'),
                  ),
                  TextButton(
                    onPressed: () => count2(count2() + 1),
                    child: const Text('increment2'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Sum: 10'), findsOneWidget);

      await tester.tap(find.text('increment1'));
      await tester.pump();
      expect(find.text('Sum: 11'), findsOneWidget);

      await tester.tap(find.text('increment2'));
      await tester.pump();
      expect(find.text('Sum: 12'), findsOneWidget);
    });

    testWidgets('signal works with different types in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final text = signal(context, 'hello');
              return Column(
                children: [
                  Text(text()),
                  TextButton(
                    onPressed: () => text('world'),
                    child: const Text('change'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('hello'), findsOneWidget);

      await tester.tap(find.text('change'));
      await tester.pump();

      expect(find.text('world'), findsOneWidget);
    });

    testWidgets('signal with nullable types in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final value = signal<String?>(context, null);
              return Column(
                children: [
                  Text(value() ?? 'null'),
                  TextButton(
                    onPressed: () => value('test'),
                    child: const Text('set'),
                  ),
                  TextButton(
                    onPressed: () => value(null, true),
                    child: const Text('clear'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('null'), findsOneWidget);

      await tester.tap(find.text('set'));
      await tester.pump();
      expect(find.text('test'), findsOneWidget);

      await tester.tap(find.text('clear'));
      await tester.pump();
      expect(find.text('null'), findsOneWidget);
    });

    testWidgets('signal does not rebuild when value is same', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              buildCount++;
              final count = signal(context, 0);
              return Column(
                children: [
                  Text('${count()}'),
                  TextButton(
                    onPressed: () => count(0),
                    child: const Text('same'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      await tester.tap(find.text('same'));
      await tester.pump();

      expect(buildCount, equals(1)); // Should not rebuild
    });
  });
}
