# 共享与会话

Family 定义如何按不可变参数创建资源，应在应用组装边界只定义一次。
family(key) 返回惰性 ResourceRef，不建实例、不请求。
Resources 按 namespace、Family 对象身份和参数相等性共享；不同目录、不同 Family 相互独立。

```dart
final article = Family<int, Query<int, String>>(
  create: (id) => Query(
    source: () => id,
    load: (id, request) async => 'Article $id',
  ),
  dispose: (query) => query.dispose(),
);

Widget app() => ResourceScope.create(
  create: () => Resources(
    namespace: () => null,
    maxIdle: 32,
    retain: const Duration(minutes: 2),
  ),
  child: MaterialApp(
    home: QueryBuilder<int, String>.shared(
      ref: article(42),
      builder: (context, state, query) => Scaffold(
        body: Center(child: Text(state.hasValue ? state.value : 'Loading…')),
      ),
    ),
  ),
);
```

Scope 在 MaterialApp 的 Navigator 上方，其他路由可消费同一 article 引用。
相等 ref 在重建时不换实例、不重复订阅。这里的缓存数值只是应用选择。
maxIdle 与 retain 必须显式配置且非负；任一为零均禁用闲置保留。

## 所有权与内存

ResourceScope.create 拥有并关闭目录；value 只借用，外部拥有者负责关闭。
资源 Builder 的 shared 自动借还，value 只观察明确外部实例，create 拥有局部实例。

最后消费者离开后暂停自动输入观察，并进入有界闲置缓存。TTL/LRU 淘汰会关闭条目并废弃读取。
活跃 UI 与未完成写不计入 maxIdle；在途写保留原实例和锁，离开再进入不能新建实例绕过 pending。

## 会话身份

```dart
typedef Session = ({Object identity, String token});
final session = Value<Session>((identity: Object(), token: 'demo-token'));

// A new login or logout creates a new identity, even for the same account.
session.value = (identity: Object(), token: 'another-demo-token');

// Token refresh within one session keeps its identity.
session.value = (identity: session.value.identity, token: 'refreshed-demo-token');
```

目录 namespace 读取 session.value.identity；token 与请求参数进入资源 source。
会话改变后已挂载 shared Builder 自动换绑，即使 ref 相等。旧读取失效；已接受写按原参数结算，
不会更新新会话 UI。同一个账号 ID 不能区分退出后重新登录的两个会话。

## 组件外使用

resources.use(ref, callback) 借用直到 callback 的 Future 完成，并在 finally 归还。
登录导航回来重新 use，避免使用导航前捕获的旧会话实例。手动创建目录由拥有者关闭。
完整示例通过 ResourceScope.value 展示外部明确持有与释放。
