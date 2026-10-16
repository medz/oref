import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  testWidgets('scoped collections retain identity and dispose widget effects', (
    tester,
  ) async {
    late ReactiveList<int> list;
    late ReactiveMap<String, int> map;
    late ReactiveSet<int> set;
    var effectRuns = 0;
    var cleanups = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            list = ReactiveList.scoped(context, [1]);
            map = ReactiveMap.scoped(context, {'first': 1});
            set = ReactiveSet.scoped(context, [1]);
            effect(context, () {
              list.length;
              map.length;
              set.length;
              effectRuns++;
              onEffectCleanup(() => cleanups++);
            });
            return Text(
              watch(
                context,
                () => '${list.length}/${map.length}/${set.length}',
              ),
            );
          },
        ),
      ),
    );

    final initialList = list;
    final initialMap = map;
    final initialSet = set;
    expect(find.text('1/1/1'), findsOneWidget);
    expect(effectRuns, 1);

    batch(() {
      list.add(2);
      map['second'] = 2;
      set.add(2);
    });
    await tester.pump();

    expect(identical(list, initialList), isTrue);
    expect(identical(map, initialMap), isTrue);
    expect(identical(set, initialSet), isTrue);
    expect(find.text('2/2/2'), findsOneWidget);
    expect(effectRuns, 2);
    expect(cleanups, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(cleanups, 2);

    batch(() {
      list.add(3);
      map['third'] = 3;
      set.add(3);
    });
    await tester.pump();
    expect(effectRuns, 2);
    expect(tester.takeException(), isNull);
  });
}
