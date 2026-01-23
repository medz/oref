import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('onMounted', () {
    testWidgets('runs after first build', (tester) async {
      bool built = false;
      bool sawBuilt = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              onMounted(context, () {
                sawBuilt = built;
              });
              built = true;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();

      expect(sawBuilt, isTrue);
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
                        onMounted(context, () {
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
      await tester.pump();

      expect(callCount, equals(1));

      setState(() {});
      await tester.pump();

      expect(callCount, equals(1));

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(callCount, equals(1));

      showChild = true;
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
                        onMounted(context, () {
                          firstCount++;
                        });
                        onMounted(context, () {
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
      await tester.pump();

      expect(firstCount, equals(1));
      expect(secondCount, equals(1));

      setState(() {});
      await tester.pump();

      expect(firstCount, equals(1));
      expect(secondCount, equals(1));

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(firstCount, equals(1));
      expect(secondCount, equals(1));

      showChild = true;
      setState(() {});
      await tester.pump();

      expect(firstCount, equals(2));
      expect(secondCount, equals(2));
    });
  });

}
