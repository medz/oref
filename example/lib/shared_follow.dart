import 'dart:async';

import 'package:flutter/material.dart' hide Action;
import 'package:oref/flutter.dart';

import 'article_pages.dart';

class DemoSession {
  DemoSession(this.account, {Object? identity, String? token})
    : identity = identity ?? Object(),
      token = account == null ? null : token ?? 'account-$account';

  DemoSession.signedOut() : this(null);

  final int? account;
  final Object identity;
  final String? token;
}

typedef ItemSource = ({Object identity, int? account, String? token, int id});

class Item {
  const Item({required this.id, required this.title, required this.followed});

  final int id;
  final String title;
  final bool? followed;

  Item withFollowed(bool value) => Item(id: id, title: title, followed: value);
}

class UnknownFollowState implements Exception {
  const UnknownFollowState();

  @override
  String toString() => '关注状态未知，请刷新后重试';
}

/// An in-memory server. These counters are simulated calls, not HTTP traffic.
class DemoApi {
  DemoApi({this.delay = const Duration(milliseconds: 350)});

  final Duration delay;
  final readCount = Value(0);
  final writeCount = Value(0);
  final _followed = <(int, int), bool>{};
  bool failNextWrite = false;
  bool unknownForSignedIn = false;
  Completer<void>? nextWriteGate;

  Future<Item> read(ItemSource source, ReadRequest request) async {
    readCount.value++;
    final ready = Completer<void>();
    final timer = Timer(delay, ready.complete);
    final cancellation = request.onCancel(() {
      timer.cancel();
      if (!ready.isCompleted) {
        ready.completeError(StateError('Read cancelled'));
      }
    });
    try {
      await ready.future;
      return Item(
        id: source.id,
        title: '山间步道',
        followed: source.account == null || unknownForSignedIn
            ? null
            : _followed[(source.account, source.id)] ?? false,
      );
    } finally {
      cancellation.dispose();
      timer.cancel();
    }
  }

  Future<void> write(ItemSource source, bool desired) async {
    final account = source.account;
    if (account == null || source.token == null) {
      throw StateError('请先登录');
    }
    writeCount.value++;
    final fail = failNextWrite;
    failNextWrite = false;
    final gate = nextWriteGate;
    nextWriteGate = null;
    if (gate != null) {
      await gate.future;
    } else {
      await Future<void>.delayed(delay);
    }
    if (fail) throw StateError('模拟保存失败，已回退');
    _followed[(account, source.id)] = desired;
  }
}

/// Two routes borrow one Query and its writable field from an owned directory.
class FollowExampleApp extends StatefulWidget {
  const FollowExampleApp({super.key, this.api, this.initialSession});

  final DemoApi? api;
  final DemoSession? initialSession;

  @override
  State<FollowExampleApp> createState() => _FollowExampleAppState();
}

class _FollowExampleAppState extends State<FollowExampleApp> {
  late final DemoApi api;
  late final Value<DemoSession> session;
  late final Resources resources;
  late final Family<int, Query<ItemSource, Item>> item;
  late final ResourceRef<RemoteValue<ItemSource, bool>> Function(int) followed;

  @override
  void initState() {
    super.initState();
    api = widget.api ?? DemoApi();
    session = Value(widget.initialSession ?? DemoSession(1));
    resources = Resources(
      namespace: () => session.value.identity,
      maxIdle: 8,
      retain: const Duration(minutes: 1),
    );
    item = Family(
      create: (int id) => Query<ItemSource, Item>(
        source: () {
          final current = session.value;
          return (
            identity: current.identity,
            account: current.account,
            token: current.token,
            id: id,
          );
        },
        load: api.read,
      ),
      dispose: (query) => query.dispose(),
    );
    followed = item.fieldAck<bool>(
      select: (item) => item.followed ?? (throw const UnknownFollowState()),
      apply: (item, desired) => item.withFollowed(desired),
      write: api.write,
    );
  }

  @override
  Widget build(BuildContext context) => ResourceScope.value(
    value: resources,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oref · 共享关注',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff52745d)),
        scaffoldBackgroundColor: const Color(0xfff7f9f5),
        useMaterial3: true,
      ),
      home: ItemPage(
        page: 'A',
        item: item(1),
        followed: followed(1),
        session: session,
        api: api,
      ),
    ),
  );

  @override
  void dispose() {
    resources.dispose();
    super.dispose();
  }
}

class ItemPage extends StatefulWidget {
  const ItemPage({
    super.key,
    required this.page,
    required this.item,
    required this.followed,
    required this.session,
    required this.api,
  });

  final String page;
  final ResourceRef<Query<ItemSource, Item>> item;
  final ResourceRef<RemoteValue<ItemSource, bool>> followed;
  final Value<DemoSession> session;
  final DemoApi api;

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  bool _continuing = false;

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final item = widget.item;
    final followed = widget.followed;
    final session = widget.session;
    final api = widget.api;
    final resources = ResourceScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('详情 $page'),
        actions: [
          IconButton(
            tooltip: '文章分页示例',
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ArticlePagesPage()),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Watch(
                builder: (_) => Text(
                  session.value.account == null
                      ? '尚未登录'
                      : '账号 ${session.value.account}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 16),
              QueryBuilder<ItemSource, Item>.shared(
                ref: item,
                builder: (context, state, query) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.hasValue ? state.value.title : '正在读取详情…',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.hasValue
                              ? '详情模型：${switch (state.value.followed) {
                                  true => '已关注',
                                  false => '未关注',
                                  null => '未知',
                                }}'
                              : '两个页面共享同一份模型与写锁。',
                          key: ValueKey('model-$page'),
                        ),
                        if (state.error != null) Text('${state.error}'),
                        const SizedBox(height: 20),
                        RemoteValueBuilder<ItemSource, bool>.shared(
                          ref: followed,
                          builder: (context, state, remote) =>
                              FilledButton.icon(
                                key: ValueKey('follow-$page'),
                                onPressed: _continuing || state.pending
                                    ? null
                                    : () async {
                                        final clickedIdentity = session
                                            .peek()
                                            .identity;
                                        var admittedIdentity = clickedIdentity;
                                        setState(() => _continuing = true);
                                        try {
                                          if (session.peek().account == null) {
                                            final selected =
                                                await Navigator.of(context)
                                                    .push<DemoSession>(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const SignInPage(),
                                                      ),
                                                    );
                                            if (!mounted ||
                                                widget.item != item ||
                                                widget.followed != followed ||
                                                !identical(
                                                  widget.session,
                                                  session,
                                                ) ||
                                                !identical(
                                                  session.peek().identity,
                                                  clickedIdentity,
                                                ) ||
                                                selected == null) {
                                              return;
                                            }
                                            session.value = selected;
                                          }
                                          final current = session.peek();
                                          final identity = current.identity;
                                          admittedIdentity = identity;
                                          if (current.account == null ||
                                              current.token == null) {
                                            return;
                                          }
                                          // Resolve descriptors again after navigation:
                                          // the new namespace owns different instances.
                                          await resources.use(item, (
                                            query,
                                          ) async {
                                            final snapshot = query.state.peek();
                                            final loaded =
                                                snapshot.error != null ||
                                                    snapshot.hasValue &&
                                                        snapshot
                                                                .value
                                                                .followed ==
                                                            null
                                                ? await query.refresh()
                                                : await query.ensureLoaded();
                                            if (!mounted ||
                                                widget.item != item ||
                                                widget.followed != followed ||
                                                !identical(
                                                  widget.session,
                                                  session,
                                                ) ||
                                                !identical(
                                                  session.peek().identity,
                                                  identity,
                                                )) {
                                              return;
                                            }
                                            if (loaded.followed == null) {
                                              throw const UnknownFollowState();
                                            }
                                            await resources.use(
                                              followed,
                                              (field) => field.update(
                                                (value) => !value,
                                              ),
                                            );
                                          });
                                        } catch (error) {
                                          if (!mounted ||
                                              !context.mounted ||
                                              widget.item != item ||
                                              widget.followed != followed ||
                                              !identical(
                                                widget.session,
                                                session,
                                              ) ||
                                              !identical(
                                                session.peek().identity,
                                                admittedIdentity,
                                              )) {
                                            return;
                                          }
                                          if (error is ResourceException &&
                                              (error.reason ==
                                                      ResourceReason.busy ||
                                                  error.reason ==
                                                      ResourceReason
                                                          .sourceChanged ||
                                                  error.reason ==
                                                      ResourceReason
                                                          .superseded)) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text('$error')),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() => _continuing = false);
                                          }
                                        }
                                      },
                                icon: Icon(
                                  state.hasValue && state.value
                                      ? Icons.star
                                      : Icons.star_outline,
                                ),
                                label: Text(
                                  state.pending
                                      ? '提交中…'
                                      : _continuing
                                      ? '处理中…'
                                      : session.peek().account == null
                                      ? '登录后关注'
                                      : !state.hasValue
                                      ? '重读关注状态'
                                      : state.value
                                      ? '已关注'
                                      : '关注',
                                ),
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => query.refresh().ignore(),
                          child: const Text('刷新详情'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (page == 'A')
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ItemPage(
                        page: 'B',
                        item: item,
                        followed: followed,
                        session: session,
                        api: api,
                      ),
                    ),
                  ),
                  child: const Text('打开第二个详情页'),
                ),
              TextButton(
                onPressed: () {
                  api.failNextWrite = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('下次提交将失败，用于观察自动回退。')),
                  );
                },
                child: const Text('让下次提交失败'),
              ),
              TextButton(
                key: const ValueKey('switch-account'),
                onPressed: () => session.value = DemoSession(
                  session.value.account == 1 ? 2 : 1,
                ),
                child: const Text('切换账号'),
              ),
              TextButton(
                key: const ValueKey('signout'),
                onPressed: () => session.value = DemoSession.signedOut(),
                child: const Text('退出登录'),
              ),
              Watch(
                builder: (_) => TextButton(
                  key: const ValueKey('refresh-token'),
                  onPressed: session.value.account == null
                      ? null
                      : () {
                          final current = session.peek();
                          if (current.account == null) return;
                          session.value = DemoSession(
                            current.account,
                            identity: current.identity,
                            token: '${current.token}-refreshed',
                          );
                        },
                  child: const Text('刷新令牌（保留会话身份）'),
                ),
              ),
              const SizedBox(height: 16),
              Watch(
                builder: (_) => Text(
                  '模拟读取 ${api.readCount.value} 次 · 模拟写入 ${api.writeCount.value} 次',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '关注先更新两个页面的完整详情模型；保存失败后自动回退。'
                '切换账号后使用独立的资源，旧请求不会覆盖新账号。',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('选择模拟登录账号')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final account in [1, 2])
            FilledButton(
              key: ValueKey('signin-account-$account'),
              onPressed: () => Navigator.of(context).pop(DemoSession(account)),
              child: Text('登录账号 $account'),
            ),
          TextButton(
            key: const ValueKey('cancel-signin'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消登录'),
          ),
        ],
      ),
    ),
  );
}
