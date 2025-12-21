import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref_examples/main.dart';

String readText(WidgetTester tester, String startsWith) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data != null &&
        widget.data!.startsWith(startsWith),
  );
  expect(finder, findsOneWidget);
  return tester.widget<Text>(finder).data ?? '';
}

Widget wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  testWidgets('counter section updates computed values', (tester) async {
    await tester.pumpWidget(wrap(const CounterSection()));
    await tester.pumpAndSettle();

    expect(readText(tester, 'count:'), contains('2.0'));
    expect(readText(tester, 'doubled (computed):'), contains('4.0'));
    expect(readText(tester, 'squared (writable):'), contains('4.0'));

    await tester.tap(find.text('Increment'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'count:'), contains('3.0'));
    expect(readText(tester, 'doubled (computed):'), contains('6.0'));
    expect(readText(tester, 'squared (writable):'), contains('9.0'));

    await tester.tap(find.text('Set squared = 81'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'count:'), contains('9.0'));
    expect(readText(tester, 'doubled (computed):'), contains('18.0'));
    expect(readText(tester, 'squared (writable):'), contains('81.0'));
  });

  testWidgets('effect and batch update summary and run count', (tester) async {
    await tester.pumpWidget(wrap(const EffectBatchSection()));
    await tester.pumpAndSettle();

    expect(readText(tester, 'a:'), contains('sum (computed): 3'));
    expect(readText(tester, 'effect runs:'), contains('1'));

    await tester.tap(find.text('Increment A'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'a:'), contains('sum (computed): 4'));
    expect(readText(tester, 'effect runs:'), contains('2'));

    await tester.tap(find.text('Batch +1 both'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'a:'), contains('sum (computed): 6'));
    expect(readText(tester, 'effect runs:'), contains('3'));
  });

  testWidgets('untrack ignores noise updates until source changes', (tester) async {
    await tester.pumpWidget(wrap(const UntrackSection()));
    await tester.pumpAndSettle();

    expect(readText(tester, 'source:'), contains('noise: 100'));
    expect(readText(tester, 'tracked:'), contains('101'));
    expect(readText(tester, 'untracked:'), contains('101'));

    await tester.tap(find.text('Bump noise'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'source:'), contains('noise: 110'));
    expect(readText(tester, 'tracked:'), contains('111'));
    expect(readText(tester, 'untracked:'), contains('101'));

    await tester.tap(find.text('Bump source'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'source:'), contains('source: 2'));
    expect(readText(tester, 'tracked:'), contains('112'));
    expect(readText(tester, 'untracked:'), contains('112'));
  });

  testWidgets('async data completes and refreshes', (tester) async {
    await tester.pumpWidget(wrap(const AsyncDataSection()));
    await tester.pumpAndSettle();

    expect(readText(tester, 'request id:'), contains('1'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(readText(tester, 'Success:'), contains('Result #1'));

    await tester.tap(find.text('Next request'));
    await tester.pump();

    expect(readText(tester, 'request id:'), contains('2'));

    await tester.pump(const Duration(milliseconds: 600));

    expect(readText(tester, 'Success:'), contains('Result #2'));
  });

  testWidgets('walkthrough section filters and adds items', (tester) async {
    await tester.pumpWidget(wrap(const WalkthroughSection()));
    await tester.pumpAndSettle();

    expect(readText(tester, 'showing'), contains('5 of 5'));
    expect(find.text('Aurora'), findsOneWidget);
    expect(find.text('Comet'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('walkthrough-query')), 'or');
    await tester.pumpAndSettle();

    expect(readText(tester, 'showing'), contains('2 of 5'));
    expect(find.text('Aurora'), findsOneWidget);
    expect(find.text('Orion'), findsOneWidget);
    expect(find.text('Comet'), findsNothing);

    await tester.tap(find.text('Clear filter'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'showing'), contains('5 of 5'));

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(find.text('Nova 1'), findsOneWidget);
    expect(readText(tester, 'showing'), contains('6 of 6'));
  });

  testWidgets('checkout walkthrough updates totals and autosave', (tester) async {
    await tester.pumpWidget(wrap(const CheckoutWorkflowSection()));
    await tester.pumpAndSettle();

    expect(readText(tester, 'qty:'), contains('1'));
    expect(readText(tester, 'total:'), contains('\$19.00'));
    expect(readText(tester, 'autosave runs:'), contains('1'));

    await tester.tap(find.text('Add 1 item'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'qty:'), contains('2'));
    expect(readText(tester, 'total:'), contains('\$38.00'));
    expect(readText(tester, 'autosave runs:'), contains('2'));

    await tester.tap(find.text('Toggle 10% promo'));
    await tester.pumpAndSettle();

    expect(readText(tester, 'discount:'), contains('10%'));
    expect(readText(tester, 'total:'), contains('\$34.20'));
    expect(readText(tester, 'autosave runs:'), contains('3'));
  });

  testWidgets('form walkthrough validates and saves', (tester) async {
    await tester.pumpWidget(wrap(const FormWorkflowSection()));
    await tester.pumpAndSettle();

    expect(readText(tester, 'valid:'), contains('no'));
    expect(readText(tester, 'can submit:'), contains('no'));
    expect(readText(tester, 'last saved:'), contains('never'));

    await tester.enterText(find.byKey(const Key('form-name')), 'Ada');
    await tester.enterText(find.byKey(const Key('form-email')), 'ada@oref.dev');
    await tester.pumpAndSettle();

    expect(readText(tester, 'valid:'), contains('yes'));
    expect(readText(tester, 'can submit:'), contains('yes'));

    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(readText(tester, 'status:'), contains('Saved'));
    expect(readText(tester, 'last saved:'), contains('just now'));
  });
}
