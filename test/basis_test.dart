import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';
import 'package:oref/src/system.dart';

void main() {
  testWidgets("track in context effect", (tester) async {
    int buildCount = 0;
    int tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            buildCount++;
            final count = useSignal(context, 0);
            return Column(
              children: [
                Text('count-${count()}'),
                TextButton(
                  onPressed: () {
                    tapCount++;
                    count(count + 1);
                  },
                  child: Text('increment'),
                ),
              ],
            );
          },
        ),
      ),
    );
    expect(find.text("count-0"), findsOneWidget);
    expect(buildCount, equals(1));
    expect(tapCount, equals(0));

    for (var i = 1; i < 5; i++) {
      await tester.tap(find.text("increment"));
      await tester.pump();
      expect(find.text("count-$i"), findsOneWidget);
      expect(buildCount, equals(i + 1));
      expect(tapCount, equals(i));
    }

    expect(buildCount, equals(5));
    expect(tapCount, equals(4));
  });

  testWidgets("not listen signal, never rebuild", (tester) async {
    int buildCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            buildCount++;
            final s = useSignal(context, 0);
            return TextButton(
              onPressed: () => s(s + 1),
              child: const Text('increment'),
            );
          },
        ),
      ),
    );

    expect(buildCount, equals(1));
    await tester.tap(find.text("increment"));
    await tester.pump();
    expect(buildCount, equals(1));
  });

  testWidgets("computed", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final count = useSignal(context, 0);
            final doubleValue = useComputed(context, (_) => count() * 2);
            return Column(
              children: [
                Text('count-${count()}'),
                Text('doubleValue-${doubleValue()}'),
                TextButton(
                  onPressed: () => count(count + 1),
                  child: Text('increment'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text("count-0"), findsOneWidget);
    expect(find.text("doubleValue-0"), findsOneWidget);
    await tester.tap(find.text("increment"));
    await tester.pump();
    expect(find.text("count-1"), findsOneWidget);
    expect(find.text("doubleValue-2"), findsOneWidget);
  });

  testWidgets("bad use hooks, reset after hooks", (tester) async {
    late int hashCode;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final one = useSignal(context, 1);
            bool bad = false;
            if (one() % 2 == 1) {
              bad = true;
              useComputed(context, (_) => one() * 2); // Bad
            }

            final three = useSignal(context, bad); // Reset
            hashCode = three.hashCode;
            return Column(
              children: [
                Text('one-${one()}'),
                Text('three-${three()}'),
                TextButton(
                  onPressed: () => one(one + 1),
                  child: Text('increment'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text("one-1"), findsOneWidget);
    expect(find.text("three-true"), findsOneWidget);

    final prevHashCode = hashCode;
    await tester.tap(find.text("increment"));
    await tester.pump();

    expect(find.text("one-2"), findsOneWidget);
    expect(find.text("three-false"), findsOneWidget);
    expect(hashCode != prevHashCode, isTrue);
  });

  testWidgets("nested hooks without context binding", (tester) async {
    dynamic cache;
    late BuildContext needsCheckContext;
    bool threeCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final s = useSignal(context, 0);
            useEffect(context, () {
              s();
              cache = useEffect(context, () {
                threeCalled = true;
              });
            });

            needsCheckContext = context;

            return TextButton(
              onPressed: () => s(s() + 1),
              child: const Text('tap'),
            );
          },
        ),
      ),
    );

    final prevCache = cache;
    await tester.tap(find.text("tap"));
    await tester.pump();

    expect(prevCache != cache, isTrue);
    expect(threeCalled, isTrue);

    final c = hooks[needsCheckContext];
    expect(c?.length, equals(2));
  });

  // testWidgets("List reaction", (tester) async {
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Builder(
  //         builder: (context) {
  //           final s = useSignal(context, <int>[]);
  //           return Column(
  //             children: [
  //               Text('length: ${s.reversed.length}'),
  //               TextButton(onPressed: () => s.add(1), child: const Text('add')),
  //               TextButton(
  //                 onPressed: () => s.removeLast(),
  //                 child: const Text('remove'),
  //               ),
  //             ],
  //           );
  //         },
  //       ),
  //     ),
  //   );

  //   expect(find.text('length: 0'), findsOneWidget);

  //   await tester.tap(find.text('add'));
  //   await tester.pump();
  //   expect(find.text('length: 1'), findsOneWidget);

  //   await tester.tap(find.text('add'));
  //   await tester.pump();
  //   expect(find.text('length: 2'), findsOneWidget);

  //   await tester.tap(find.text('remove'));
  //   await tester.pump();
  //   expect(find.text('length: 1'), findsOneWidget);
  // });
}
