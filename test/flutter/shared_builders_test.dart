import 'dart:async';

import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/flutter.dart';

Widget host(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('leaving and returning cannot bypass a shared pending write', (
    tester,
  ) async {
    final resources = Resources(
      namespace: () => null,
      maxIdle: 0,
      retain: Duration.zero,
    );
    addTearDown(resources.dispose);
    var reads = 0;
    var writes = 0;
    final gate = Completer<void>();
    final family = Family<int, RemoteValue<int, bool>>(
      create: (id) => RemoteValue.ack(
        source: () => id,
        read: (source, request) {
          reads++;
          return false;
        },
        write: (source, value) {
          writes++;
          return gate.future;
        },
      ),
      dispose: (remote) => remote.dispose(),
    );
    late RemoteValue<int, bool> remote;
    Widget page(bool show) => host(
      ResourceScope.value(
        value: resources,
        child: show
            ? RemoteValueBuilder<int, bool>.shared(
                ref: family(1),
                builder: (_, state, resource) {
                  remote = resource;
                  return Text('${state.pending}');
                },
              )
            : const SizedBox(),
      ),
    );
    await tester.pumpWidget(page(true));
    await tester.pump();
    final original = remote;
    final accepted = remote.set(true);
    await tester.pump();
    await tester.pumpWidget(page(false));
    await tester.pumpWidget(page(true));
    await tester.pump();
    expect(identical(remote, original), isTrue);
    expect(find.text('true'), findsOneWidget);
    await expectLater(
      remote.set(false),
      throwsA(
        isA<ResourceException>().having(
          (error) => error.reason,
          'reason',
          ResourceReason.busy,
        ),
      ),
    );
    expect(reads, 1);
    expect(writes, 1);
    gate.complete();
    expect(await accepted, isTrue);
    await tester.pump();
    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('shared queries reuse an equal ref and rebind on namespace ABA', (
    tester,
  ) async {
    final firstIdentity = Object();
    final namespace = Value(firstIdentity);
    final resources = Resources(
      namespace: () => namespace.value,
      maxIdle: 4,
      retain: const Duration(minutes: 1),
    );
    addTearDown(resources.dispose);
    var reads = 0;
    final family = Family<int, Query<int, String>>(
      create: (id) => Query<int, String>(
        source: () => id,
        load: (id, request) => 'read:${++reads}',
      ),
      dispose: (query) => query.dispose(),
    );
    Query<int, String>? first;
    Query<int, String>? second;
    Widget page() => host(
      ResourceScope.value(
        value: resources,
        child: Column(
          children: [
            QueryBuilder<int, String>.shared(
              ref: family(1),
              builder: (_, state, resource) {
                first = resource;
                return Text('A:${state.hasValue ? state.value : 'loading'}');
              },
            ),
            QueryBuilder<int, String>.shared(
              ref: family(1),
              builder: (_, state, resource) {
                second = resource;
                return Text('B:${state.hasValue ? state.value : 'loading'}');
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(page());
    await tester.pump();
    final original = first;
    expect(identical(first, second), isTrue);
    expect(reads, 1);
    for (var rebuild = 0; rebuild < 100; rebuild++) {
      await tester.pumpWidget(page());
      await tester.pump();
    }
    expect(identical(first, original), isTrue);
    expect(reads, 1);

    namespace.value = Object();
    namespace.value = firstIdentity;
    await tester.pump();
    await tester.pump();
    expect(identical(first, original), isFalse);
    expect(identical(first, second), isTrue);
    expect(find.text('A:read:2'), findsOneWidget);
    expect(reads, 2);
    await tester.pumpWidget(const SizedBox());
    resources.dispose();
  });

  testWidgets('shared fields reuse their parent Query and optimistic model', (
    tester,
  ) async {
    final resources = Resources(
      namespace: () => null,
      maxIdle: 0,
      retain: Duration.zero,
    );
    addTearDown(resources.dispose);
    var reads = 0;
    final item = Family<int, Query<int, ({int id, bool followed})>>(
      create: (id) => Query(
        source: () => id,
        load: (id, request) {
          reads++;
          return (id: id, followed: false);
        },
      ),
      dispose: (query) => query.dispose(),
    );
    final followed = item.fieldAck<bool>(
      select: (item) => item.followed,
      apply: (item, value) => (id: item.id, followed: value),
      write: (id, value) {},
    );
    late RemoteValue<int, bool> remote;
    await tester.pumpWidget(
      host(
        ResourceScope.value(
          value: resources,
          child: Column(
            children: [
              QueryBuilder<int, ({int id, bool followed})>.shared(
                ref: item(1),
                builder: (_, state, resource) => Text(
                  state.hasValue ? 'model:${state.value.followed}' : 'loading',
                ),
              ),
              RemoteValueBuilder<int, bool>.shared(
                ref: followed(1),
                builder: (_, state, resource) {
                  remote = resource;
                  return Text(
                    state.hasValue ? 'field:${state.value}' : 'loading',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(reads, 1);
    await remote.set(true);
    await tester.pump();
    expect(find.text('model:true'), findsOneWidget);
    expect(find.text('field:true'), findsOneWidget);
    expect(reads, 1);
  });

  testWidgets('Scope.value borrows while Scope.create closes its directory', (
    tester,
  ) async {
    Resources directory() =>
        Resources(namespace: () => null, maxIdle: 0, retain: Duration.zero);
    final borrowed = directory();
    final owned = directory();
    addTearDown(borrowed.dispose);
    final action = Family<int, Action<int, int>>(
      create: (_) => Action(execute: (value) => value),
      dispose: (action) => action.dispose(),
    );
    await tester.pumpWidget(
      ResourceScope.value(value: borrowed, child: const SizedBox()),
    );
    await tester.pumpWidget(
      ResourceScope.create(create: () => owned, child: const SizedBox()),
    );
    expect(await borrowed.use(action(1), (action) => action.run(4)), 4);
    await tester.pumpWidget(const SizedBox());
    await expectLater(
      owned.use(action(1), (action) => action.run(4)),
      throwsA(isA<ResourceException>()),
    );
  });
}
