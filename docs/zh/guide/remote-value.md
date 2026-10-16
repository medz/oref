# RemoteValue 与可写字段

RemoteValue 表达可读取和替换的远端值。它立即显示 desired，拒绝并发写，保存失败回退原值。
适用于设置、开关和模型字段。

## 独立远端值

```dart
import 'package:oref/oref.dart';

Future<void> main() async {
  var stored = false; // In-memory server for this example.
  final newsletter = RemoteValue<String, bool>.ack(
    source: () => 'newsletter',
    read: (key, request) async => stored,
    write: (key, desired) async { stored = desired; },
  );
  try {
    await newsletter.ensureLoaded();
    await newsletter.update((current) => !current);
    print(newsletter.state.value.value); // true
  } finally {
    newsletter.dispose();
  }
}
```

普通构造器的 writer 返回服务端 canonical 值；ack 的 writer 只确认成功，采用 desired。
默认不在写后 GET，也不自动重试写。

独立远端值的 set/update 都需要可靠当前值，不隐式加载。未知时先明确 await
ensureLoaded 或 refresh。set 表达目标值，update 根据当前值计算。Seed 将初始数据与 source 绑定且只消费一次，不能因重建或换源重复注入。
accept 可接收新的权威数据，要求 source 匹配且没有正在进行的读写。

独立值可用 identity(source) 区分业务值身份与传输 token。身份改变清掉旧值与 seed 资格；
已接受写仍保持原参数和锁直到真实结算。

## Query 模型的一个字段

在组装边界定义一次父资源和字段：

```dart
class Item {
  const Item(this.id, this.followed);
  final int id;
  final bool followed;
}

final serverFollowed = <int, bool>{};
final item = Family<int, Query<int, Item>>(
  create: (id) => Query(
    source: () => id,
    load: (id, request) async => Item(id, serverFollowed[id] ?? false),
  ),
  dispose: (query) => query.dispose(),
);
final followed = item.fieldAck<bool>(
  select: (item) => item.followed,
  apply: (item, desired) => Item(item.id, desired),
  write: (id, desired) async { serverFollowed[id] = desired; },
);
```

将 ResourceScope 放在 Navigator 上方，再消费字段引用：

```dart
RemoteValueBuilder<int, bool>.shared(
  ref: followed(42),
  builder: (context, state, remote) => IconButton(
    onPressed: !state.hasValue || state.pending
        ? null
        : () => remote.update((current) => !current).ignore(),
    icon: Icon(
      state.hasValue && state.value ? Icons.star : Icons.star_outline,
    ),
    tooltip: state.error?.toString(),
  ),
)
```

Query 拥有唯一完整模型。select 读取字段，apply 只替换所属字段并返回新模型，往返必须保留
期望字段值。field 的 writer 返回 canonical 值；fieldAck 只确认 desired。
字段继承父 source、GET、写锁和缓存条目，不另建输入订阅、TTL、identity 或 seed。

字段写开始废弃旧 GET；写入时父读取和兄弟字段写都返回 busy。乐观、提交和回退一起更新父模型
与各字段。父 source 中 token 改变也会清值并重读，字段不独立保留 identity。

未知字段投影可以失败而不让父 Query 加载失败。父模型已加载时，字段 set 允许直接提供
未知字段的目标值；update 仍要求投影当前值可靠。显式释放字段只关闭该 view，不释放父在途写锁；
父资源释放时关闭全部 view。源码的双页面关注示例包含完整共享、失败回退与账号切换。
