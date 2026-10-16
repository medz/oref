import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/flutter.dart' hide Action;
import 'package:oref_examples/shared_follow.dart';

Future<void> loaded(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump();
}

void fullViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('two routes reuse one detail and share optimistic rollback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = DemoApi(delay: const Duration(milliseconds: 10));
    await tester.pumpWidget(FollowExampleApp(api: api));
    await loaded(tester);
    expect(api.readCount.peek(), 1);
    await tester.tap(find.text('打开第二个详情页'));
    await tester.pumpAndSettle();
    expect(api.readCount.peek(), 1);

    final gate = Completer<void>();
    api.nextWriteGate = gate;
    api.failNextWrite = true;
    await tester.tap(find.byKey(const ValueKey('follow-B')));
    await tester.pump();
    expect(api.writeCount.peek(), 1);
    expect(find.text('详情模型：已关注', skipOffstage: false), findsNWidgets(2));
    for (final page in ['A', 'B']) {
      final button = tester.widget<FilledButton>(
        find.byKey(ValueKey('follow-$page'), skipOffstage: false),
      );
      expect(button.onPressed, isNull);
    }

    gate.complete();
    await loaded(tester);
    expect(find.text('详情模型：未关注', skipOffstage: false), findsNWidgets(2));
    expect(api.readCount.peek(), 1);
    expect(find.textContaining('模拟保存失败'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switching account isolates an accepted old write', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = DemoApi(delay: const Duration(milliseconds: 10));
    await tester.pumpWidget(FollowExampleApp(api: api));
    await loaded(tester);
    final gate = Completer<void>();
    api.nextWriteGate = gate;
    await tester.tap(find.byKey(const ValueKey('follow-A')));
    await tester.pump();
    expect(find.text('详情模型：已关注'), findsOneWidget);
    await tester.ensureVisible(find.text('切换账号'));
    await tester.tap(find.text('切换账号'));
    await loaded(tester);
    expect(find.text('账号 2'), findsOneWidget);
    expect(find.text('详情模型：未关注'), findsOneWidget);
    expect(api.readCount.peek(), 2);

    gate.complete();
    await loaded(tester);
    expect(find.text('详情模型：未关注'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('follow-A')));
    await tester.tap(find.byKey(const ValueKey('follow-A')));
    await loaded(tester);
    expect(api.writeCount.peek(), 2);
    expect(find.text('详情模型：已关注'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'cancelled sign-in keeps the signed-out namespace and issues no write',
    (tester) async {
      fullViewport(tester);
      final initial = DemoSession.signedOut();
      final api = DemoApi(delay: const Duration(milliseconds: 10));
      await tester.pumpWidget(
        FollowExampleApp(api: api, initialSession: initial),
      );
      await loaded(tester);
      final session = tester.widget<ItemPage>(find.byType(ItemPage)).session;
      expect(find.text('详情模型：未知'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('follow-A')));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cancel-signin')));
      await tester.pumpAndSettle();
      expect(session.peek(), same(initial));
      expect(api.writeCount.peek(), 0);
      expect(api.readCount.peek(), 1);
      expect(find.text('尚未登录'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'successful sign-in continues the original click in the new namespace',
    (tester) async {
      fullViewport(tester);
      final initial = DemoSession.signedOut();
      final api = DemoApi(delay: const Duration(milliseconds: 10));
      await tester.pumpWidget(
        FollowExampleApp(api: api, initialSession: initial),
      );
      await loaded(tester);
      final session = tester.widget<ItemPage>(find.byType(ItemPage)).session;
      await tester.tap(find.byKey(const ValueKey('follow-A')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('signin-account-2')));
      await tester.pumpAndSettle();
      expect(session.peek().account, 2);
      expect(identical(session.peek().identity, initial.identity), isFalse);
      expect(find.text('账号 2'), findsOneWidget);
      expect(find.text('详情模型：已关注'), findsOneWidget);
      expect(api.readCount.peek(), 2);
      expect(api.writeCount.peek(), 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'account changes during sign-in cannot be overwritten or continued',
    (tester) async {
      fullViewport(tester);
      final api = DemoApi(delay: const Duration(milliseconds: 10));
      await tester.pumpWidget(
        FollowExampleApp(api: api, initialSession: DemoSession.signedOut()),
      );
      await loaded(tester);
      final session = tester.widget<ItemPage>(find.byType(ItemPage)).session;
      await tester.tap(find.byKey(const ValueKey('follow-A')));
      await tester.pumpAndSettle();
      final external = DemoSession(2);
      session.value = external;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('signin-account-1')));
      await tester.pumpAndSettle();
      expect(session.peek(), same(external));
      expect(find.text('账号 2'), findsOneWidget);
      expect(find.text('详情模型：未关注'), findsOneWidget);
      expect(api.writeCount.peek(), 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'removing the waiting detail route prevents session installation and write',
    (tester) async {
      fullViewport(tester);
      final initial = DemoSession.signedOut();
      final api = DemoApi(delay: const Duration(milliseconds: 10));
      await tester.pumpWidget(
        FollowExampleApp(api: api, initialSession: initial),
      );
      await loaded(tester);
      final session = tester.widget<ItemPage>(find.byType(ItemPage)).session;
      await tester.tap(find.text('打开第二个详情页'));
      await tester.pumpAndSettle();
      final detail = ModalRoute.of(tester.element(find.byType(ItemPage)))!;
      await tester.tap(find.byKey(const ValueKey('follow-B')));
      await tester.pumpAndSettle();
      final navigator = Navigator.of(tester.element(find.byType(SignInPage)));
      navigator.removeRoute(detail);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('signin-account-1')));
      await tester.pumpAndSettle();
      expect(find.text('详情 A'), findsOneWidget);
      expect(session.peek(), same(initial));
      expect(api.writeCount.peek(), 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'signed-in unknown stays unknown and only a click explicitly reads again',
    (tester) async {
      fullViewport(tester);
      final api = DemoApi(delay: const Duration(milliseconds: 10))
        ..unknownForSignedIn = true;
      await tester.pumpWidget(FollowExampleApp(api: api));
      await loaded(tester);
      expect(find.text('详情模型：未知'), findsOneWidget);
      expect(find.text('重读关注状态'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(api.readCount.peek(), 1);
      await tester.tap(find.byKey(const ValueKey('follow-A')));
      await tester.pumpAndSettle();
      expect(api.readCount.peek(), 2);
      expect(api.writeCount.peek(), 0);
      expect(find.text('详情模型：未知'), findsOneWidget);
      expect(find.text('关注状态未知，请刷新后重试'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.readCount.peek(), 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'changing the item reference during sign-in prevents continuation',
    (tester) async {
      fullViewport(tester);
      final api = DemoApi(delay: const Duration(milliseconds: 10));
      final initial = DemoSession.signedOut();
      final session = Value(initial);
      final resources = Resources(
        namespace: () => session.value.identity,
        maxIdle: 2,
        retain: const Duration(minutes: 1),
      );
      final item = Family<int, Query<ItemSource, Item>>(
        create: (id) => Query(
          source: () => (
            identity: session.value.identity,
            account: session.value.account,
            token: session.value.token,
            id: id,
          ),
          load: api.read,
        ),
        dispose: (query) => query.dispose(),
      );
      final followed = item.fieldAck<bool>(
        select: (model) => model.followed ?? (throw const UnknownFollowState()),
        apply: (model, value) => model.withFollowed(value),
        write: api.write,
      );
      var id = 1;
      late StateSetter rebuildHome;
      await tester.pumpWidget(
        ResourceScope.value(
          value: resources,
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                rebuildHome = setState;
                return ItemPage(
                  page: 'A',
                  item: item(id),
                  followed: followed(id),
                  session: session,
                  api: api,
                );
              },
            ),
          ),
        ),
      );
      await loaded(tester);
      await tester.tap(find.byKey(const ValueKey('follow-A')));
      await tester.pumpAndSettle();
      rebuildHome(() => id = 2);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('signin-account-1')));
      await tester.pumpAndSettle();
      expect(session.peek(), same(initial));
      expect(api.writeCount.peek(), 0);
      expect(find.text('详情模型：未知'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      resources.dispose();
    },
  );

  testWidgets(
    'an accepted old-account failure does not prompt the new account',
    (tester) async {
      fullViewport(tester);
      final api = DemoApi(delay: const Duration(milliseconds: 10));
      await tester.pumpWidget(FollowExampleApp(api: api));
      await loaded(tester);
      final gate = Completer<void>();
      api.nextWriteGate = gate;
      api.failNextWrite = true;
      await tester.tap(find.byKey(const ValueKey('follow-A')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('switch-account')));
      await tester.tap(find.byKey(const ValueKey('switch-account')));
      await loaded(tester);
      gate.complete();
      await loaded(tester);
      expect(find.text('账号 2'), findsOneWidget);
      expect(find.text('详情模型：未关注'), findsOneWidget);
      expect(find.textContaining('模拟保存失败'), findsNothing);
      expect(api.writeCount.peek(), 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'external sign-out disables token refresh through its observation',
    (tester) async {
      fullViewport(tester);
      final api = DemoApi(delay: const Duration(milliseconds: 10));
      await tester.pumpWidget(FollowExampleApp(api: api));
      await loaded(tester);
      final session = tester.widget<ItemPage>(find.byType(ItemPage)).session;
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('refresh-token')))
            .onPressed,
        isNotNull,
      );
      session.value = DemoSession.signedOut();
      await loaded(tester);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('refresh-token')))
            .onPressed,
        isNull,
      );
      expect(find.text('尚未登录'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
