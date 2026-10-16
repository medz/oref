import 'dart:async';

import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/flutter.dart';

Widget host(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

Matcher reason(ResourceReason reason) =>
    isA<ResourceException>().having((error) => error.reason, 'reason', reason);

void main() {
  testWidgets('plain parent input changes reject an old in-flight result', (
    tester,
  ) async {
    final oldRead = Completer<String>();
    late Query<int, String> query;
    Widget page(int id) => host(
      QueryBuilder<int, String>.create(
        source: () => id,
        load: (source, request) => source == 1 ? oldRead.future : 'new input',
        builder: (_, state, resource) {
          query = resource;
          return Text(state.hasValue ? state.value : 'loading');
        },
      ),
    );
    await tester.pumpWidget(page(1));
    final original = query;
    final oldAttempt = query.ensureLoaded();
    oldAttempt.ignore();
    await tester.pumpWidget(page(2));
    await tester.pump();
    expect(identical(query, original), isTrue);
    expect(find.text('new input'), findsOneWidget);
    await expectLater(
      oldAttempt,
      throwsA(reason(ResourceReason.sourceChanged)),
    );
    oldRead.complete('stale response');
    await tester.pump();
    expect(find.text('new input'), findsOneWidget);
  });

  testWidgets('lazy builders capture the current immutable resource snapshot', (
    tester,
  ) async {
    var version = 1;
    late Query<int, List<int>> query;
    await tester.pumpWidget(
      host(
        QueryBuilder<int, List<int>>.create(
          source: () => 1,
          load: (source, request) => [version],
          builder: (_, state, resource) {
            query = resource;
            return ListView.builder(
              itemCount: state.hasValue ? state.value.length : 0,
              itemBuilder: (_, index) => Text('item:${state.value[index]}'),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('item:1'), findsOneWidget);
    version = 2;
    await query.refresh();
    await tester.pump();
    expect(find.text('item:2'), findsOneWidget);
    expect(find.text('item:1'), findsNothing);
  });

  testWidgets('owning query starts outside build and uses latest callbacks', (
    tester,
  ) async {
    var reads = 0;
    late Query<int, String> query;
    Widget page(int id, String prefix) => host(
      QueryBuilder<int, String>.create(
        source: () => id,
        load: (source, request) {
          reads++;
          return '$prefix:$source';
        },
        builder: (_, state, resource) {
          query = resource;
          return Text(state.hasValue ? state.value : 'loading');
        },
      ),
    );
    await tester.pumpWidget(page(1, 'first'));
    await tester.pump();
    expect(find.text('first:1'), findsOneWidget);
    expect(reads, 1);

    await tester.pumpWidget(page(1, 'latest'));
    await tester.pump();
    expect(reads, 1);
    expect(await query.refresh(), 'latest:1');
    await tester.pump();
    await tester.pumpWidget(page(2, 'next'));
    await tester.pump();
    expect(find.text('next:2'), findsOneWidget);
    expect(reads, 3);

    await tester.pumpWidget(const SizedBox());
    await expectLater(
      query.refresh(),
      throwsA(reason(ResourceReason.disposed)),
    );
  });

  testWidgets('value neither activates nor disposes a borrowed query', (
    tester,
  ) async {
    var reads = 0;
    final query = Query<int, int>(
      source: () => 1,
      load: (source, request) => ++reads,
    );
    addTearDown(query.dispose);
    await tester.pumpWidget(
      host(
        QueryBuilder.value(
          value: query,
          builder: (_, state, resource) =>
              Text(state.hasValue ? '${state.value}' : 'not started'),
        ),
      ),
    );
    await tester.pump();
    expect(reads, 0);
    expect(find.text('not started'), findsOneWidget);
    await query.ensureLoaded();
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(await query.refresh(), 2);
  });

  testWidgets('create to value disposes owned but never borrowed resource', (
    tester,
  ) async {
    late Query<int, int> owned;
    final borrowed = Query<int, int>(
      source: () => 9,
      load: (source, request) => source,
    );
    addTearDown(borrowed.dispose);
    await tester.pumpWidget(
      host(
        QueryBuilder<int, int>.create(
          source: () => 1,
          load: (source, request) => source,
          builder: (_, state, resource) {
            owned = resource;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      host(
        QueryBuilder<int, int>.value(
          value: borrowed,
          builder: (_, state, resource) => const SizedBox(),
        ),
      ),
    );
    await expectLater(
      owned.refresh(),
      throwsA(reason(ResourceReason.disposed)),
    );
    await tester.pumpWidget(const SizedBox());
    expect(await borrowed.ensureLoaded(), 9);
  });

  testWidgets('automatic read errors stay in state without unhandled futures', (
    tester,
  ) async {
    final failure = StateError('load failed');
    await tester.pumpWidget(
      host(
        QueryBuilder<int, int>.create(
          source: () => 1,
          load: (source, request) => throw failure,
          builder: (_, state, resource) => Text('${state.error}'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('$failure'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ActionBuilder never runs automatically and replaces execute', (
    tester,
  ) async {
    late Action<int, String> action;
    var writes = 0;
    Widget page(String prefix) => host(
      ActionBuilder<int, String>.create(
        execute: (arguments) {
          writes++;
          return '$prefix:$arguments';
        },
        builder: (_, state, resource) {
          action = resource;
          return Text(state.hasValue ? state.value : 'idle');
        },
      ),
    );
    await tester.pumpWidget(page('first'));
    await tester.pump();
    expect(writes, 0);
    expect(await action.run(1), 'first:1');
    await tester.pumpWidget(page('latest'));
    expect(await action.run(2), 'latest:2');
    await tester.pump();
    expect(find.text('latest:2'), findsOneWidget);
  });

  testWidgets('PagesBuilder changes cursor callback without replacing items', (
    tester,
  ) async {
    late Pages<int, int, int> pages;
    Widget page(int cursor) => host(
      PagesBuilder<int, int, int>.create(
        source: () => 1,
        load: (source, cursor, request) => [cursor ?? 0],
        nextCursor: (source, items) => items.single == 0 ? cursor : null,
        builder: (_, state, resource) {
          pages = resource;
          return Text(state.items.join(','));
        },
      ),
    );
    await tester.pumpWidget(page(1));
    await tester.pump();
    await tester.pumpWidget(page(2));
    // The already accepted first-page cursor is kept; future pages use the
    // newest nextCursor callback rather than mutating previous page results.
    expect(await pages.loadMore(), [1]);
    await tester.pump();
    expect(find.text('0,1'), findsOneWidget);
  });

  testWidgets(
    'RemoteValueBuilder updates callbacks and consumes initial once',
    (tester) async {
      late RemoteValue<int, bool> remote;
      final writes = <String>[];
      Widget page(String label, bool initial) => host(
        RemoteValueBuilder<int, bool>.ack(
          source: () => 1,
          initial: Seed(source: 1, value: initial),
          write: (source, value) => writes.add('$label:$value'),
          builder: (_, state, resource) {
            remote = resource;
            return Text(state.hasValue ? '${state.value}' : 'unknown');
          },
        ),
      );
      await tester.pumpWidget(page('first', false));
      await tester.pump();
      await tester.pumpWidget(page('latest', true));
      expect(find.text('false'), findsOneWidget);
      expect(await remote.update((value) => !value), isTrue);
      expect(writes, ['latest:true']);
      await tester.pump();
      expect(find.text('true'), findsOneWidget);
    },
  );
}
