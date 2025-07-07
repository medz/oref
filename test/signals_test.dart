import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

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
}
