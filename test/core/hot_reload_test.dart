import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Computed Callback Update hot reload', (tester) async {
    bool switchFn = false;
    late Element element;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            element = context as Element;

            final s = signal(context, 1);
            double fn1(_) => s() * 2.1;
            double fn2(_) => s() * 2.0;

            final c = computed(context, switchFn ? fn2 : fn1);
            return Text('${c()}');
          },
        ),
      ),
    );

    expect(find.text('2.1'), findsOneWidget);

    switchFn = true;
    element.markNeedsBuild();
    await tester.pump();

    expect(find.text('2.0'), findsOneWidget);
  });
}
