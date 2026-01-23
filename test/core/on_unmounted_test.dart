import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('onUnmounted', () {
    testWidgets('runs when widget is unmounted', (tester) async {
      int callCount = 0;
      bool showChild = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, updateState) {
              setState = updateState;
              return showChild
                  ? Builder(
                      builder: (context) {
                        onUnmounted(context, () {
                          callCount++;
                        });
                        return const SizedBox();
                      },
                    )
                  : const SizedBox();
            },
          ),
        ),
      );

      expect(callCount, equals(0));

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(callCount, equals(1));
    });

    testWidgets('runs once per element and reruns after remount', (
      tester,
    ) async {
      int callCount = 0;
      bool showChild = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, updateState) {
              setState = updateState;
              return showChild
                  ? Builder(
                      builder: (context) {
                        onUnmounted(context, () {
                          callCount++;
                        });
                        return const SizedBox();
                      },
                    )
                  : const SizedBox();
            },
          ),
        ),
      );

      expect(callCount, equals(0));

      setState(() {});
      await tester.pump();

      expect(callCount, equals(0));

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(callCount, equals(1));

      showChild = true;
      setState(() {});
      await tester.pump();

      expect(callCount, equals(1));

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(callCount, equals(2));
    });

    testWidgets('runs multiple hooks in same widget', (tester) async {
      int firstCount = 0;
      int secondCount = 0;
      bool showChild = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, updateState) {
              setState = updateState;
              return showChild
                  ? Builder(
                      builder: (context) {
                        onUnmounted(context, () {
                          firstCount++;
                        });
                        onUnmounted(context, () {
                          secondCount++;
                        });
                        return const SizedBox();
                      },
                    )
                  : const SizedBox();
            },
          ),
        ),
      );

      expect(firstCount, equals(0));
      expect(secondCount, equals(0));

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(firstCount, equals(1));
      expect(secondCount, equals(1));

      showChild = true;
      setState(() {});
      await tester.pump();

      expect(firstCount, equals(1));
      expect(secondCount, equals(1));

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(firstCount, equals(2));
      expect(secondCount, equals(2));
    });
  });
}
