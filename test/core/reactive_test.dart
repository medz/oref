import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

class Counter with Reactive<Counter> {
  int _value = 0;

  int get value {
    track();
    return _value;
  }

  void increment() {
    _value++;
    trigger();
  }

  void decrement() {
    _value--;
    trigger();
  }

  void set(int newValue) {
    _value = newValue;
    trigger();
  }

  void refresh() {
    trigger();
  }
}

class Point with Reactive<Point> {
  int _x = 0;
  int _y = 0;

  int get x {
    track();
    return _x;
  }

  int get y {
    track();
    return _y;
  }

  void setX(int value) {
    _x = value;
    trigger();
  }

  void setY(int value) {
    _y = value;
    trigger();
  }

  void move(int x, int y) {
    _x = x;
    _y = y;
    trigger();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reactive', () {
    test('tracks reactive getter', () {
      int effectCount = 0;
      final counter = Counter();

      effect(null, () {
        counter.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      counter.increment();
      expect(effectCount, equals(2));
    });

    test('reactive value updates correctly', () {
      final counter = Counter();

      expect(counter.value, equals(0));

      counter.increment();
      expect(counter.value, equals(1));

      counter.increment();
      expect(counter.value, equals(2));

      counter.decrement();
      expect(counter.value, equals(1));
    });

    test('trigger notifies dependents', () {
      int effectCount = 0;
      final counter = Counter();

      effect(null, () {
        counter.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      counter.set(10);
      expect(effectCount, equals(2));
      expect(counter.value, equals(10));
    });

    test('multiple effects on same reactive', () {
      int effect1Count = 0;
      int effect2Count = 0;
      final counter = Counter();

      effect(null, () {
        counter.value;
        effect1Count++;
      });

      effect(null, () {
        counter.value;
        effect2Count++;
      });

      expect(effect1Count, equals(1));
      expect(effect2Count, equals(1));

      counter.increment();
      expect(effect1Count, equals(2));
      expect(effect2Count, equals(2));
    });

    test('reactive with multiple properties', () {
      int effectCount = 0;
      final point = Point();

      effect(null, () {
        point.x;
        point.y;
        effectCount++;
      });

      expect(effectCount, equals(1));

      point.setX(5);
      expect(effectCount, equals(2));

      point.setY(10);
      expect(effectCount, equals(3));

      point.move(20, 30);
      expect(effectCount, equals(4));
    });

    test('computed from reactive', () {
      final counter = Counter();
      final doubled = computed(null, (_) => counter.value * 2);

      expect(doubled(), equals(0));

      counter.increment();
      expect(doubled(), equals(2));

      counter.set(10);
      expect(doubled(), equals(20));
    });

    test('reactive does not trigger when not modified', () {
      int effectCount = 0;
      final counter = Counter();

      effect(null, () {
        counter.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      // Trigger without actually changing value
      counter.refresh();
      expect(effectCount, equals(2));
    });

    test('untrack with reactive', () {
      int effectCount = 0;
      final counter = Counter();

      effect(null, () {
        untrack(() => counter.value);
        effectCount++;
      });

      expect(effectCount, equals(1));

      counter.increment();
      expect(effectCount, equals(1)); // Should not trigger
    });

    test('batch with reactive', () {
      int effectCount = 0;
      final counter1 = Counter();
      final counter2 = Counter();

      effect(null, () {
        counter1.value;
        counter2.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      batch(() {
        counter1.increment();
        counter2.increment();
      });

      expect(effectCount, equals(2)); // Should run only once
    });

    test('reactive with conditional tracking', () {
      int effectCount = 0;
      final condition = signal(null, true);
      final counter1 = Counter();
      final counter2 = Counter();

      effect(null, () {
        condition() ? counter1.value : counter2.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      counter1.increment();
      expect(effectCount, equals(2));

      counter2.increment(); // Not tracked
      expect(effectCount, equals(2));

      condition.set(false);
      expect(effectCount, equals(3));

      counter1.increment(); // Not tracked anymore
      expect(effectCount, equals(3));

      counter2.increment();
      expect(effectCount, equals(4));
    });

    test('reactive disposed with effect', () {
      int effectCount = 0;
      final counter = Counter();

      final dispose = effect(null, () {
        counter.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      counter.increment();
      expect(effectCount, equals(2));

      dispose();

      counter.increment();
      expect(effectCount, equals(2)); // Should not run after dispose
    });

    test('multiple reactive instances', () {
      final counter1 = Counter();
      final counter2 = Counter();

      counter1.set(5);
      counter2.set(10);

      expect(counter1.value, equals(5));
      expect(counter2.value, equals(10));

      counter1.increment();
      expect(counter1.value, equals(6));
      expect(counter2.value, equals(10));
    });

    test('reactive with complex computed logic', () {
      final point = Point();
      final distance = computed(null, (_) {
        final x = point.x;
        final y = point.y;
        return (x * x + y * y).toDouble();
      });

      expect(distance(), equals(0.0));

      point.setX(3);
      expect(distance(), equals(9.0));

      point.setY(4);
      expect(distance(), equals(25.0)); // 3^2 + 4^2 = 25

      point.move(0, 0);
      expect(distance(), equals(0.0));
    });
  });

  group('Reactive with Flutter Widget Context', () {
    testWidgets('reactive tracks in widget', (tester) async {
      final counter = Counter();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final count = signal(context, counter.value);
              effect(context, () {
                count.set(counter.value);
              });
              return Column(
                children: [
                  Text('${count()}'),
                  TextButton(
                    onPressed: counter.increment,
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

    testWidgets('reactive triggers widget rebuild', (tester) async {
      final counter = Counter();
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              buildCount++;
              final value = signal(context, counter.value);
              effect(context, () {
                value.set(counter.value);
              });
              return Column(
                children: [
                  Text('${value()}'),
                  TextButton(
                    onPressed: counter.increment,
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

    testWidgets('multiple reactive properties in widget', (tester) async {
      final point = Point();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final x = signal(context, point.x);
              final y = signal(context, point.y);
              effect(context, () {
                x.set(point.x);
                y.set(point.y);
              });
              return Column(
                children: [
                  Text('X: ${x()}, Y: ${y()}'),
                  TextButton(
                    onPressed: () => point.setX(point.x + 1),
                    child: const Text('inc x'),
                  ),
                  TextButton(
                    onPressed: () => point.setY(point.y + 1),
                    child: const Text('inc y'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('X: 0, Y: 0'), findsOneWidget);

      await tester.tap(find.text('inc x'));
      await tester.pump();
      expect(find.text('X: 1, Y: 0'), findsOneWidget);

      await tester.tap(find.text('inc y'));
      await tester.pump();
      expect(find.text('X: 1, Y: 1'), findsOneWidget);
    });

    testWidgets('computed from reactive in widget', (tester) async {
      final counter = Counter();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final value = signal(context, counter.value);
              effect(context, () {
                value.set(counter.value);
              });
              final doubled = computed(context, (_) => value() * 2);
              return Column(
                children: [
                  Text('Doubled: ${doubled()}'),
                  TextButton(
                    onPressed: counter.increment,
                    child: const Text('increment'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Doubled: 0'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump();

      expect(find.text('Doubled: 2'), findsOneWidget);
    });

    testWidgets('reactive with conditional tracking in widget',
        (tester) async {
      final counter1 = Counter();
      final counter2 = Counter();
      counter2.set(10);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final condition = signal(context, true);
              final result = signal(context, 0);
              effect(context, () {
                result.set(condition() ? counter1.value : counter2.value);
              });
              return Column(
                children: [
                  Text('Result: ${result()}'),
                  TextButton(
                    onPressed: () => condition.set(!condition()),
                    child: const Text('toggle'),
                  ),
                  TextButton(
                    onPressed: counter1.increment,
                    child: const Text('inc 1'),
                  ),
                  TextButton(
                    onPressed: counter2.increment,
                    child: const Text('inc 2'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Result: 0'), findsOneWidget);

      await tester.tap(find.text('inc 1'));
      await tester.pump();
      expect(find.text('Result: 1'), findsOneWidget);

      await tester.tap(find.text('toggle'));
      await tester.pump();
      expect(find.text('Result: 10'), findsOneWidget);

      await tester.tap(find.text('inc 2'));
      await tester.pump();
      expect(find.text('Result: 11'), findsOneWidget);
    });

    testWidgets('reactive with complex computed in widget', (tester) async {
      final point = Point();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final x = signal(context, point.x);
              final y = signal(context, point.y);
              effect(context, () {
                x.set(point.x);
                y.set(point.y);
              });
              final distance = computed(context, (_) {
                return (x() * x() + y() * y()).toDouble();
              });
              return Column(
                children: [
                  Text('Distance: ${distance()}'),
                  TextButton(
                    onPressed: () => point.setX(3),
                    child: const Text('set x to 3'),
                  ),
                  TextButton(
                    onPressed: () => point.setY(4),
                    child: const Text('set y to 4'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Distance: 0.0'), findsOneWidget);

      await tester.tap(find.text('set x to 3'));
      await tester.pump();
      expect(find.text('Distance: 9.0'), findsOneWidget);

      await tester.tap(find.text('set y to 4'));
      await tester.pump();
      expect(find.text('Distance: 25.0'), findsOneWidget);
    });
  });
}
