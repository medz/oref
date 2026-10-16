# Query

Query 为一份不可变输入加载一个结果。QueryBuilder.create 创建、启动并释放局部实例。
下面是组件内片段，articleId 是当前组件参数；导入 Material 与 Oref Flutter 入口。

```dart
QueryBuilder<int, String>.create(
  source: () => articleId,
  load: (id, request) async => 'Article $id',
  builder: (context, state, query) => Column(
    children: [
      if (state.pending) const LinearProgressIndicator(),
      if (state.hasValue) Text(state.value),
      if (state.error != null) Text('${state.error}'),
      TextButton(
        onPressed: () => query.refresh().ignore(),
        child: const Text('Refresh'),
      ),
    ],
  ),
)
```

## 输入与回调

source 是同步函数，只有其中同步 Readable 读取成为请求依赖。它应只组装简单值或不可变
record，loader 中的读取不会成为输入。输入通过 Dart == 比较，应包含所有影响结果的参数。
组件更新时安装最新回调；相同输入不会因为闭包换了就重读。已经开始的操作保留原输入和回调。

输入改变时清掉旧值、废弃旧读取，并在激活后读取新输入。Flutter Key 不承担请求身份。
source 求值错误会清掉旧显示并公开 error/stackTrace，后续合法输入可恢复。

| 状态 | 含义 |
| --- | --- |
| hasSource / source | 已解析的合法输入，可为 null。 |
| hasValue / value | 已加载结果，可为合法 null。 |
| pending | 读取进行中。 |
| error / stackTrace | 当前读取或输入错误。 |

未检查 has 标记直接读不存在的 source/value 会抛 StateError。
快照不可变，可在惰性列表闭包中安全捕获。

ensureLoaded 复用当前进行中或最近尝试的 Future，包括失败尝试，不因重新订阅隐式重试。
refresh 在没有读取时新建尝试；重复进行中读取复用同一个 Future。
相同输入刷新保留已有值，刷新失败也保留该值。

## 外部拥有

手动创建的 Query 由创建者 ensureLoaded/refresh 并负责 dispose。
QueryBuilder.value 只观察；跨页面共享使用[Family](./sharing.md)与 shared 构造器。
修改模型字段使用 [field 或 fieldAck](./remote-value.md)。
