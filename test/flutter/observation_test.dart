import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/flutter.dart';

Widget host(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets(
    'Watch follows branches and keeps sibling observations separate',
    (tester) async {
      final branch = Value(true);
      final a = Value(1);
      final b = Value(2);
      var firstBuilds = 0;
      var secondBuilds = 0;

      await tester.pumpWidget(
        host(
          Column(
            children: [
              Watch(
                builder: (_) {
                  firstBuilds++;
                  return Text('first:${branch.value ? a.value : b.value}');
                },
              ),
              Watch(
                builder: (_) {
                  secondBuilds++;
                  return Text('second:${b.value}');
                },
              ),
            ],
          ),
        ),
      );
      a.value++;
      await tester.pump();
      expect(firstBuilds, 2);
      expect(secondBuilds, 1);

      branch.value = false;
      await tester.pump();
      a.value++;
      await tester.pump();
      expect(firstBuilds, 3);
      b.value++;
      await tester.pump();
      expect(firstBuilds, 4);
      expect(secondBuilds, 2);

      await tester.pumpWidget(const SizedBox());
      b.value++;
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(firstBuilds, 4);
    },
  );

  testWidgets('a throwing nested builder restores tracking and can recover', (
    tester,
  ) async {
    final fail = Value(true);
    final sibling = Value(0);
    var outerBuilds = 0;
    var siblingBuilds = 0;
    await tester.pumpWidget(
      host(
        Watch(
          builder: (_) {
            outerBuilds++;
            return Column(
              children: [
                SizedBox(
                  height: 100,
                  child: Watch(
                    builder: (_) {
                      if (fail.value) throw StateError('build failed');
                      return const Text('recovered');
                    },
                  ),
                ),
                Watch(
                  builder: (_) {
                    siblingBuilds++;
                    return Text('sibling:${sibling.value}');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
    expect(tester.takeException(), isStateError);
    fail.value = false;
    await tester.pump();
    expect(find.text('recovered'), findsOneWidget);
    expect(outerBuilds, 1);
    sibling.value++;
    await tester.pump();
    expect(siblingBuilds, 2);
    expect(outerBuilds, 1);
  });

  testWidgets('invalidation during a build schedules a safe following build', (
    tester,
  ) async {
    final value = Value(0);
    await tester.pumpWidget(
      host(
        Watch(
          builder: (_) {
            final before = value.value;
            if (before == 0) value.value = 1;
            return Text('$before');
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StateBuilder owns once and captures its original disposer', (
    tester,
  ) async {
    final lifecycleRead = Value(0);
    final disposed = <String>[];
    var creates = 0;
    var updates = 0;
    var builds = 0;
    late Value<int> count;

    Widget page(int identity, String label) => host(
      StateBuilder<Value<int>>(
        identity: identity,
        create: () {
          lifecycleRead.value;
          creates++;
          return count = Value(identity);
        },
        update: (_) {
          lifecycleRead.value;
          updates++;
        },
        dispose: (value) {
          lifecycleRead.value;
          disposed.add('$label:${value.peek()}');
        },
        builder: (_, value) {
          builds++;
          return Text('$label:${value.value}');
        },
      ),
    );

    await tester.pumpWidget(page(1, 'first'));
    count.value = 9;
    await tester.pump();
    expect(find.text('first:9'), findsOneWidget);
    await tester.pumpWidget(page(1, 'latest'));
    expect(creates, 1);
    expect(updates, 1);
    final before = builds;
    lifecycleRead.value++;
    await tester.pump();
    expect(builds, before);
    await tester.pumpWidget(page(2, 'second'));
    expect(creates, 2);
    expect(disposed, ['first:9']);
    await tester.pumpWidget(const SizedBox());
    expect(disposed, ['first:9', 'second:2']);
  });

  testWidgets('StateBuilder.value changes the observation without ownership', (
    tester,
  ) async {
    final first = Value(1);
    final second = Value(2);
    var builds = 0;
    Widget page(Value<int> value) => host(
      StateBuilder.value(
        value: value,
        builder: (_, value) {
          builds++;
          return Text('${value.value}');
        },
      ),
    );
    await tester.pumpWidget(page(first));
    await tester.pumpWidget(page(second));
    first.value++;
    await tester.pump();
    expect(builds, 2);
    second.value++;
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(builds, 3);
  });
}
