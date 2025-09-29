import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  testWidgets("track in widget", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            final count = signal(context, 0);
            return Column(
              children: [
                Text("${count.value}"),
                TextButton(
                  child: const Text("increment"),
                  onPressed: () => count.value++,
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
}
