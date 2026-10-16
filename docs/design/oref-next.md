# Oref 3.0 RFC

状态：Oref 3.0 的全新 API 与资源模型设计，核心决策1–11已确认。独立与字段 RemoteValue 均纳入3.0稳定设计目标；开发实现与行为测试已完成，当前开发版本尚未发布。目标是解决完整真实项目的重复协议、共享、传参和生命周期样板，不以最小首发范围替代完整设计。旧 API、兼容性与现行锁定版本不构成约束；响应底座继续使用 alien_signals，以最新已发布稳定版本展开设计，不重写信号内核。

Oref 面向 Flutter 的完整业务状态。业务提供输入、请求、计算和业务决策；库管理订阅、资源生命周期和重复的执行协议。常用入口是查询、分页和动作，不要求业务先创建 Store、Provider 或 Owner。

本设计以通用文章分页与跨路由共享关注作为验收场景。公开示例和测试只使用模拟服务及本地测试服务；私有应用仅作为本地开发参考，不参与发布。

## 设计结论

继续使用 alien_signals 作为响应底座，在其上提供普通 Dart 资源实例和薄的 Flutter 适配器。Value、Computed、Subscription、batch 是用户 API 的薄适配，不重新实现信号、依赖图、脏传播或 effect 队列。实例是状态与执行锁的归属；输入是请求参数；组件是一个可选的拥有者。三个概念分别表达。

| 层 | 最小能力 | 职责 |
| --- | --- | --- |
| 信号适配 | Readable、Value、Computed、batch、Subscription | 复用 alien_signals 的同步值、动态依赖和批处理 |
| 读取资源 | Query、Pages | 查询、刷新、分页和过期读取 |
| 写入资源 | Action | 显式执行、互斥和结果 |
| 远端可写值 | RemoteValue | 独立值或Query字段的读取、替换、乐观显示和回退 |
| 共享目录 | Family、Resources | 按定义和参数查找共享资源，管理借用、闲置缓存和释放 |
| Flutter 适配 | Watch、各资源 Builder、StateBuilder、ResourceScope | 订阅、持有、更新配置、目录接入和释放 |

已确认 Query、Pages、Action、RemoteValue 为3.0稳定设计目标，使用同步source与三参数builder。第8项确认 Query.field/fieldAck 返回 RemoteValue 字段视图；第9项确认独立值与字段视图一并纳入稳定设计，覆盖此前实验定位，发布前必须通过实现验收。它不承担实体归一化、并发字段合并或跨资源事务。第4项共享入口采用 Family、Resources、ResourceScope；第6项确认生命周期与操作保活，第10项确认同父写锁及写优先，第11项确认根目录显式配置缓存容量与时长。

包保持一个产品，提供两个完整入口：oref.dart 导出纯 Dart 状态与资源，flutter.dart 导出同样的 API 加 Flutter 适配器。纯 Dart 测试导入前者，Flutter 页面导入后者。内部依赖方向保持 core → resources → shared → flutter；本稿不承诺无需 Flutter SDK 就能解析整个包的 Flutter SDK 依赖。

~~~text
lib/
  oref.dart
  flutter.dart
  src/
    core/       readable, value, computed, subscription, batch, alien_adapter
    resources/  resource library与query/pages/action/remote_value/read_request parts
    shared/     shared library与family/resources parts
    flutter/    watch, state_builder, query_builder, pages_builder, action_builder, remote_value_builder, resource_scope
test/
  core/
  resources/
  flutter/
~~~

resources 内未从公开入口导出的配置函数负责更换回调；Flutter 导入这些包内函数，不让资源层导入 Flutter，也不依靠跨 Dart library 的私有字段访问。支持的公开 API 只来自上述两个入口。调试扩展和 analyzer 不进入3.0运行依赖。

## 产品边界和默认行为

减少的目标是重复协议，而不是正常的 HTTP、JSON、模型、权限和 UI 代码。

默认请求由首次接入、显式输入变化和显式操作触发。普通构建、DevTools 检查和重复订阅不触发请求。同一资源的重复读取合并；刷新分页只重新取第一页。自动重试、定时刷新、恢复焦点刷新和全局缓存均不在第一阶段默认行为中。

普通本地值用 Value；重计算且复用的同步值用 Computed；事件回调用普通 Dart 函数。简单展示条件和长度直接计算，不为每个 UI 字段创建 Computed。

3.0 不依赖代码生成、字段代理、可变集合拦截、位置式 hooks、全局隐式实例注册表、全实体缓存、自动 invalidation 图或通用乐观事务。共享目录由应用明确创建；消费者可以通过稳定定义和参数获取同一实例，不要求沿组件与路由逐层传递实例。StateBuilder 合并局部对象的持有与同步观察，也允许业务显式持有多个资源；外部资源的清理代码仍需完整展示。

## 数据和操作身份

### 对象实例

一个 Query、Pages、Action 或独立 RemoteValue 对象拥有自己的状态和执行锁；Query字段RemoteValue共享父模型和写锁。相同输入的两个独立实例不共享数据、请求或pending。共享可以显式传同一个实例，也可以由应用目录按同一定义和参数取得同一实例。

由组件创建的资源归该组件所有；由会话或应用创建的资源归该拥有者所有。消费者只能释放自己的订阅。

### 同步输入函数

Query、Pages 和独立 RemoteValue 的source统一为同步的 S Function()，返回不可变参数快照。字段RemoteValue继承父Query的source，不另建输入订阅。

~~~dart
source: () => (
  category: categoryId,
  take: 20,
  session: auth.value,
)
~~~

只有这个输入函数内部的同步 Readable 读取建立依赖。loader、writer 和 Action.execute 在未跟踪环境执行；await 前后的业务读取不会隐式成为请求依赖。

资源构造不发送请求。Query/Pages 第一次 ensureLoaded 或 refresh 激活输入订阅；RemoteValue 第一次 ensureLoaded、refresh、set/update 或 accept 激活订阅。第一次激活由调用入口决定是否读取及 ReadReason，不能额外插入 initial 抢先覆盖显式 refresh。激活后，输入依赖变化触发重新求值并按资源协议切换输入。每个准备接受工作的操作入口也同步重新求值 source，因此登录导航返回后执行动作不必等待 Flutter 下一帧更新输入。关闭检查早于求值，disposed 方法不会再执行用户 source 函数。Pages 未激活时 loadMore 返回 notReady，不启动首屏或持久订阅。

Flutter 的 owning Builder 在 didUpdateWidget 更换最新 source/load/write/next 回调，然后重新求值 source。相同输入与新闭包不导致重复请求。已开始的操作固定使用接受时的输入与回调；以后的操作使用最新回调。

参数使用 Dart ==，不做序列化或深比较。支持基本值、enum、不可变 record 和有明确值相等语义的对象。原地修改 List/Map 后再次传同一引用不在协议内。纯业务参数变化由 source 表达；Flutter Key 只决定子树是否重建，例如是否重置滚动位置。

每个操作入口的额外成本为一次 source 求值和一次相等比较。这个函数应只组装输入，不做 JSON、过滤大列表、HTTP 或昂贵纯计算。多个输入同时更新使用 batch，复用 alien_signals 的 effect 批处理；不另加全局事务阶段，也不承诺涉及重入写时每个资源严格只求值一次。

source 求值抛错时，资源停止展示先前输入的数据，隔离读取发布资格，并记录 source 错误；本次异步操作返回以原错误与堆栈完成的 Future，不调用 loader/writer。Remote 同时递增写发布 epoch，但保留旧写锁直到真实结算。已接受写入保留固定输入并正常结算。错误依赖仍被保留，输入变化后可以恢复；即使恢复到上次相等 source，也不能恢复旧显示或重用旧 seed。

source 错误同时清掉旧来源的尝试缓存并令 hasSource=false。恢复合法输入时视为新的有效来源，按资源规则建立一次读取；不能返回错误前的成功值，也不能把输入求值异常作为这个合法来源的最近读取结果。

所有资源的 dispose 幂等，释放内部输入订阅、读取登记和调度，禁止新操作。state 仍可读最后已发布的不可变快照；它不表示关闭对象还能接受操作。外部 state 订阅归消费者释放，dispose 不代替借用者清理自己的观察者。关闭后不再向 state 发布结算。

source 应由业务输入组成，不应读取自身结果或形成资源间反馈循环。Oref 只用资源自身的执行/求值标记阻止同步递归入口，不建立第二个依赖图或扫描全图检测任意环；本稿不承诺底座会把所有循环变成 StateError。静态 source 的底层 effect 没有信号依赖。

### 会话身份

令牌是传输参数，不是全局缓存键。应用每次登录、退出或替换会话创建新的身份对象；同一会话内刷新令牌保留身份。

~~~dart
typedef SessionState = ({
  Object identity,
  UserSession? session,
  bool ready,
});

final auth = Value<SessionState>((
  identity: Object(),
  session: null,
  ready: false,
));
~~~

这是应用数据类型，不是必须继承的 Oref 类。身份对象不序列化，也不写入日志。账号 ID 本身不足以区分退出后重新登录的两个会话。

独立 RemoteValue 可以通过identity(S)提取值的业务身份，例如会话身份与条目ID。source中令牌变化但identity不变时，未来操作使用新令牌，现有值保留；已接受写继续用旧令牌结算。identity改变时清掉旧值和初始数据资格。Query字段视图继承父Query的完整source比较，token变化会清值并重新读取；这是已确认接受的不同来源合同，不另设字段identity。

## 完整公开 API 合同

以下是接口合同，不是可执行的实现文件。构造器和状态对象只公开保证的能力；算法、调度和内部字段在后文定义。

### 信号适配

~~~dart
abstract interface class Subscription {
  void dispose(); // 幂等
}

abstract interface class Readable<T> {
  T get value;   // 跟踪当前同步观察者
  T peek();     // 不订阅调用者，仍返回当前计算结果
  Subscription subscribe(void Function() listener);
}

class Value<T> implements Readable<T> {
  Value(T initial);
  T get value;
  set value(T next);
  T peek();
  Subscription subscribe(void Function() listener);
}

class Computed<T> implements Readable<T> {
  Computed(T Function() calculate);
  T get value;
  T peek();
  Subscription subscribe(void Function() listener);
}

R batch<R>(R Function() changes);
~~~

一个 Value 包含一个底层 SignalNode，一个 Computed 包含一个底层 ComputedNode；不为同一个业务值再保存第二个信号或镜像数据。value 转发底层读取，Value 的 setter 转发底层写入，Computed 包装固定的 calculate。信号与计算结果的变化判断沿用底座 identical，不改为 ==；资源 source 参数的 == 比较是请求层的独立规则。不可变 List/Map 改变时替换实例，3.0不公开可变集合拦截。

Value 和 Computed 不要求公开 dispose。消费者释放自己创建的 Subscription；停止底层 effect 负责解除它的依赖。底座决定 Computed 的依赖与缓存生命期：最后一个订阅解除时可释放上游边，但用户仍保存的 Computed 允许保留最后值或错误；无人观察时直接读取也不保证零依赖或零缓存。构造时未求值的 Computed 不主动执行 calculate。

subscribe 将一个底层 effect 包装为 Subscription：底座 effect 创建立即执行，适配器首次只读取目标，不调用用户 listener；后续目标变化才调用 listener，listener 的业务读取放在未跟踪区，不能变成这个订阅的新依赖。创建独立订阅时同样退出调用者的跟踪区，避免成为正在构建的父 effect 的子资源。dispose 幂等并停止该 effect。Oref 在这个业务回调边界捕获登记时的 Zone，以 runGuarded 交付 listener 异常；这是薄的 Dart 回调包装，不能称为底座内建保证，也不延伸到任意外部 alien effect。通知次序与重入传播遵循底座，不增加订阅快照总线，不承诺每事务一次交付或所有外部 effect 异常后的队列继续执行。

peek 使用底座 active subscriber 的未跟踪作用域读取；保存前一个 subscriber，并在 finally 恢复。它只阻止调用者订阅，不关闭 Computed 自己正常的依赖跟踪。事件回调通常已在跟踪环境之外，正常读 value 即可。

Computed 的计算函数在其生命期内固定，动态业务输入用 Readable 表达。computed 错误缓存和依赖变化后的重算沿用底座，不增加另一份缓存。batch 只包装底座 startBatch/endBatch，并用 finally 保证异常时结束；它只覆盖同步执行部分，await 后的修改不属于这个批次，不增加底座没有提供的异步回调拒绝或回滚能力。

### Future 和错误

~~~dart
final class ResourceException implements Exception {
  const ResourceException(this.reason);
  final ResourceReason reason;
}

enum ResourceReason {
  busy,
  disposed,
  notReady,
  noReader,
  sourceChanged,
  superseded,
}
~~~

所有异步资源方法返回原生 Future<T>，不公开 Outcome、不实现自定义 Future 句柄。成功完成为业务值；source、loader、writer、execute 或 update 回调失败，以原错误对象和原堆栈完成为 error，不包装成另一层失败类型。调用点使用普通 await/try/catch 续接导航和业务；持续错误显示读取 state.error/state.stackTrace。

当前资源自身产生的ResourceException表达拒绝或失效：busy/disposed/notReady/noReader表示本次工作未启动，不覆盖业务错误状态；sourceChanged表示来源失效，superseded表示读取被替代。它们不宣称HTTP已停止；dispose让活动读取以disposed结束。用户update/apply回调自身抛错按原错误交付，并仅在原source仍有效时记录写错误，零HTTP；不能只按异常类型跳过ResourceException。已接受写的回调自身抛错同样交付并记录，即使委托的另一资源返回ResourceException；这与当前资源在入口拒绝工作不同。已接受写不因UI消失改为失效错误，仍以写入自身的值或原错误结算。

异步方法同步返回 Future；即使 source 或 update 变换同步抛错，也通过返回 Future 的 error 交付，避免同一方法混用同步 throw 与异步 error。内部用 Completer.completeError(error, stackTrace) 保留堆栈。RemoteValue.accept 是同步方法，成功返回 T，失败直接抛对应控制异常或原错误；原错误用 Error.throwWithStackTrace 保留堆栈。快照在无数据时读 value 仍直接抛 StateError；通用信号的计算、内层写入和循环行为沿用底座，不能把 Oref 的使用约束误当成新增的运行时检查。

Future 的错误消费遵循原生 Dart 规则。显式操作必须 await 并处理错误、注册 onError，或在明确只通过 state 展示错误时调用 ignore()；只写 await、不加 catch 仍可能让错误向上冒泡。库触发的自动首次加载和 source 切换读取、owning Builder 的启动，都在启动点对公开 Future 调 ignore()，避免自动读取产生无人处理的错误；它不改变该 Future 的结果，后续调用者仍能等待同一个 Future 并收到错误。库不为显式调用悄悄安装全局吞错处理器。

### 取消读取

~~~dart
enum ReadReason { initial, refresh, append }

abstract interface class ReadRequest {
  ReadReason get reason;
  bool get cancelled;
  Subscription onCancel(void Function() cancel);
}
~~~

onCancel 返回可撤销的登记。若已经 cancelled，登记时立即调用一次；登记回调与取消均幂等。操作结束后清掉登记。一个取消回调抛错不能阻止其他回调和操作结算。

HTTP 客户端是否支持请求级 abort 由适配代码决定。每次请求只能登记属于本次请求的取消动作，不能关闭其他资源正在使用的共享客户端。没有登记时，失效读取仍被拒收，其 HTTP 可能继续运行。

reason 表达本次读取目的。组合资源首次 read 可加入上游 ensureLoaded，明确刷新则调用上游 refresh；否则包装资源的 refresh 可能只取到上游旧缓存。reason 不允许 loader 修改资源调度。

### Query

~~~dart
class QueryState<S, T> {
  bool get hasSource;
  S get source; // hasSource=false 时 StateError；S 本身可以为 nullable
  bool get hasValue;
  T get value; // hasValue=false 时 StateError；T 本身可以为 nullable
  bool get pending;
  Object? get error;
  StackTrace? get stackTrace;
}

class Query<S, T> {
  Query({
    required S Function() source,
    required FutureOr<T> Function(S, ReadRequest) load,
  });
  Readable<QueryState<S, T>> get state;
  Future<T> ensureLoaded();
  Future<T> refresh();
  void dispose();
}
~~~

ensureLoaded 在当前输入第一次启动一次请求。完成后返回这个输入最近一次尝试的 Future，包括失败的 Future；重试使用 refresh。当前输入已经有读取进行时，ensureLoaded 和 refresh 返回同一个 Future 对象。source 改变后没有旧输入的值。

同输入刷新期间保留已有值；失败保留值并公开 error。成功值是 null 与从未有值通过 hasValue 区分。state 不允许外部改 data/status/error；3.0 Query 不提供随意 setData。

### Pages

~~~dart
enum PagePhase { idle, initial, refresh, append }

class PagesState<S, T, C> {
  bool get hasSource;
  S get source;
  List<T> get items; // 当前构建可安全捕获的不可变快照
  bool get hasLoaded;
  PagePhase get phase;
  bool get hasNext;
  Object? get error;
  StackTrace? get stackTrace;
  Object? get nextError;
  StackTrace? get nextStackTrace;
}

class Pages<S, T, C extends Object> {
  Pages({
    required S Function() source,
    required FutureOr<List<T>> Function(S, C?, ReadRequest) load,
    required C? Function(S, List<T>) nextCursor,
  });
  Readable<PagesState<S, T, C>> get state;
  Future<List<T>> ensureLoaded();
  Future<List<T>> refresh();
  Future<List<T>> loadMore();
  void dispose();
}
~~~

T 是条目，C 是游标，null 表示没有下一页。因此游标类型应为非 nullable 类型。nextCursor 收到本次输入和本页结果；返回 null 时结束。库不猜测 page size、最后 ID 或重复条目的业务意义。

phase 是单一状态，不能同时 refreshing 与 loadingMore。error 属于首屏/刷新，nextError 属于追加。成功追加清 nextError，失败保留 items 和可重试游标。空页必须返回 null；继续返回相同游标属于协议错误，以 StateError 完成本次 Future 并记录到相应错误字段，保留既有列表，不形成无限请求。

ensureLoaded/refresh 成功返回所加载的第一页，loadMore 成功返回本次新增页；它们不返回当时累计列表。累计 items 只从当前快照取得，避免调用者误把后来追加或新 source 的列表当作本次操作结果。

### Action

~~~dart
class ActionState<R> {
  bool get pending;
  bool get hasValue;
  R get value; // hasValue=false 时 StateError；R 本身可以为 nullable
  Object? get error;
  StackTrace? get stackTrace;
}

class Action<A, R> {
  Action({required FutureOr<R> Function(A) execute});
  Readable<ActionState<R>> get state;
  Future<R> run(A arguments);
  void dispose();
}
~~~

调用时接受一个不可变参数快照。同一实例最多一条已接受操作；忙碌时新调用返回以 ResourceException(busy) 完成的 Future。不合并两个写、不自动排队、不自动重试。参数相同不意味着两个写可以去重。

新操作接受时清掉旧 value/error/stackTrace，令 hasValue=false、pending=true。execute 成功时发布 hasValue=true 与结果（包括合法 null）；失败时保持 hasValue=false，发布原 error 与 stackTrace；两种终态都清 pending。被拒绝的调用不清既有结果。dispose 禁止接受新操作并释放内部登记；已接受操作仍执行，以原返回值或原错误完成其 Future，停止向已关闭资源发布状态。对写入的服务器副作用不作撤销保证。

### 独立 RemoteValue

~~~dart
class Seed<S, T> {
  Seed({required this.source, required this.value});
  final S source;
  final T value;
}

class RemoteState<S, T> {
  bool get hasSource;
  S get source;
  bool get hasValue;
  T get value;
  bool get loading; // 读取中
  bool get pending; // 已接受的写仍未结算
  Object? get error;
  StackTrace? get stackTrace;
}

class RemoteValue<S, T> {
  RemoteValue({
    required S Function() source,
    Object? Function(S)? identity,
    Seed<S, T>? initial,
    FutureOr<T> Function(S, ReadRequest)? read,
    required FutureOr<T> Function(S, T desired) write,
  });
  RemoteValue.ack({
    required S Function() source,
    Object? Function(S)? identity,
    Seed<S, T>? initial,
    FutureOr<T> Function(S, ReadRequest)? read,
    required FutureOr<void> Function(S, T desired) write,
  });
  Readable<RemoteState<S, T>> get state;
  Future<T> ensureLoaded();
  Future<T> refresh();
  Future<T> set(T desired);
  Future<T> update(T Function(T current) change);
  T accept(Seed<S, T> authoritative);
  void dispose();
}
~~~

默认 write 返回服务器确认后的 canonical T，成功采用它。ack 的服务端只确认成功，没有返回值；成功采用本次 desired，不宣称已经回读权威值。两种接口不把 Future<void> 伪装成服务器数据。

没有提供 identity 时，以完整 source 的 == 作为业务身份，nullable source 也合法。自定义 identity 返回 null 同样是一个合法身份值。

update 不隐式发读取或等待加载。当前没有可靠值时返回以 ResourceException(notReady) 完成的 Future，调用者明确 await ensureLoaded 后再 update。owned Builder 配置 read 时，初次接入自动 ensureLoaded。独立Remote的read可以复用另一个Query的同一请求，但不提供模型级协调；模型字段修改使用下方已确认的Query字段视图，继承父级读取与写入协调。

initial 是带来源的初始化数据，在首次激活时匹配或丢弃，一次消费。第一次 source 解析失败也丢弃 initial。A → B → A、source 异常后恢复和组件普通重建都不能复用这个旧 seed；更新 Builder 的 initial 属性也不重新消费。换账号后不能给旧的 followed 值重新贴上新身份。新的权威回填使用 accept。

accept 检查当前 source 与 identity，来源不匹配抛 ResourceException(sourceChanged)，写/读取忙碌时抛 ResourceException(busy)，关闭时抛 ResourceException(disposed)。采纳后返回 authoritative.value。没有服务器 revision 时，库不能判定两个外部结果谁更权威；调用者只向 accept 交付已确定可采纳的数据。Seed 证明数据归属，不证明它比另一条服务器响应更新。

Remote ensureLoaded 先加入当前读取 Future，再检查已有值，避免刷新时返回旧缓存。没有 read 时，ensureLoaded 仍激活 source；有可靠 seed 返回以该值完成的 Future，没有值以 ResourceException(notReady) 完成，均零 HTTP。refresh 没有 read 时以 ResourceException(noReader) 完成。

完整优先级为：closed → resolve source 失败 → 写锁 busy → 当前读取 Future → 当前 source 最近有效尝试/已接受 seed/提交值的缓存 Future → 首次 read。失败读取也保留其 Future，ensureLoaded 不隐式重试；明确 refresh 才新读。成功 write 或 accept 建立当前值的缓存 Future。无 read 且无值时为 notReady。

set/update 在写锁存在时一律以 ResourceException(busy) 完成，不执行 update 函数；3.0不增加“相同 desired 合并写”的例外。idle 时 desired == 当前提交值直接返回以该值完成的 Future，零 HTTP。update 的同步变换必须为纯函数，先有重入守卫，只调用一次，成功后再核对 alive/source epoch 并接受写。变换导致来源改变则以 StateError 完成，变换期间关闭则以 ResourceException(disposed) 完成，均不发写请求；对同资源的递归操作以 busy 完成，不允许一个变换启动两笔写。变换本身抛错保留原错误与堆栈。

## alien_signals 适配边界

依赖图、边的建立与解除、computed 的缓存/失效、脏传播和 effect 批处理全部使用 alien_signals 的 preset。Oref 不维护 collector stack、第二份边表、全局节点版本或另一条响应调度队列。2026-10-16重新核对pub.dev后，3.0底座使用最新稳定alien_signals2.3.5。旧2.x的^2.3.2与lock仅为历史现场，不冻结新版。已校验 2.3.5 发布档 SHA256 并比较源码；当前公开 API 与 system 接口没有新增适配要求，升级包含 batch 队列与嵌套 computed 错误恢复修复。实施时重新核对稳定发布与必要行为，不把本地 checkout 或未发布分支当最新版本。

Oref 需要的底座能力只有 signal/computed、effect 停止、active subscriber 的同步作用域，以及 startBatch/endBatch。Value/Computed 的每次读取直接进入同一底层节点；Subscription 对底层 effect 做第一次通知跳过与 dispose 包装。资源用一个底层输入 effect 跟踪 source，状态发布使用一个底层信号保存完整不可变快照；不把快照的各字段再复制成多份信号。

资源求值、Widget build 和未跟踪区只在同步调用栈内改变 active subscriber，每次保存旧值并在 finally 恢复。async 回调开始前退出该跟踪区，await 后也不继承它。效应依赖的收集和旧边解除使用 preset 的执行/清理能力；仅 setActiveSub 不足以完成一轮动态依赖更新，不能重复旧版仅设 subscriber 而不结束跟踪的接线。底层 effect 的停止和未跟踪作用域由底座 API 完成，Oref 不自行逐边清理。

底座没有提供“所有资源 source 先于外部订阅”的独立阶段。Oref 不作这个保证，也不保证多个资源与普通 Value 在任意同步 listener 中构成统一事务快照。资源协议只保证自己的不可变快照、操作 epoch 和固定请求参数；显式操作入口重新取 source，读取提交前再次核对来源，避免依赖 effect 交付次序来决定是否允许写入或发布旧数据。

计算函数、source 和 Widget builder 应保持纯粹。alien_signals 支持 effect 中写入；Oref 不另加一个覆盖所有信号的写禁令或通用循环探测器。直接资源重入由局部执行标记处理，复杂反馈图不在支持的使用方式中。业务 subscribe 回调的未跟踪与 Zone 包装是 Oref 自己的小型适配；不把它扩写成任意底座 effect 的异常隔离、剩余队列继续交付或零闲置缓存合同。

## 读取调度和状态机

### 共同操作记录

每次读取记录 source 快照、source epoch、操作种类、捕获的 loader、取消登记和 Completer。公开 Future 在执行 loader 前创建并保存；开始方法不额外 async 包装，以便重复调用返回同一个 Future。

~~~text
startRead(kind):
  closed → Future.error(ResourceException(disposed))，不求值 source
  同步 resolve source，必要时切 epoch
  source抛错 → Future.error(原error, 原stackTrace)
  如已有可合并 operation，直接返回其 future
  建立 operation；先存 active，再 publish pending
  通知返回后再次检查 active / epoch / alive
  安排 loader 微任务；执行微任务时再次检查资格
  调用捕获的 loader，消费同步 throw 和异步 error

finishRead(operation, result):
  若已关闭或active != operation，只清理旧操作，不再求值source
  在未跟踪区复核当前source；改变/抛错则按切源协议使旧读失效
  如 active != operation 或 epoch 变了，只清理旧操作
  否则先撤下旧 active、记录终态
  Query记录本次尝试；Pages仅initial/refresh更新首屏尝试，append不覆盖它
  publish 当前 success/failure 快照
  最后以本次业务值或原error/stackTrace完成公开Future
  不再清任何全局active，listener可能已创建新操作

invalidateRead(reason):
  递增 epoch，撤下旧 active
  立即以ResourceException(reason)完成它的公开Future
  发送一次取消信号
  消费旧 loader 最终完成，禁止它清新操作的 pending
~~~

取消和失效都不等待旧 HTTP 返回。完成、失效、同步通知期间的 reentrant dispose 与 source 更新也必须守住 active 指针，不能因为用户 listener 同步执行操作而让旧 finally 清掉新状态。

资源接受与结算的清理/Completer完成放在finally边界；不能让快照通知层的异常留下永久pending或未完成Future，也不能把通知错误改写成HTTP/writer的业务失败。Oref的subscribe包装负责用户listener错误交付；底座或外部effect异常不因此获得全局恢复保证。

内部必须消费被失效 loader 的最终完成或 error；它不能二次完成公开 Future，也不能把取消造成的传输异常发布到新状态。公开 Future 的失效控制错误仍遵循调用者的 await/catch/ignore 责任。

### Query 状态

~~~text
idle → pending 无值 → success 有值
                  → failure 无值
有值 → pending 保留值 → success 替换值
                    → failure 保留值
source 改变 → 清旧值并启动新 source
dispose → 拒绝新读、失效旧读、拆订阅
~~~

纯依赖变化只为激活过的资源自动启动 initial 读取；未激活构造仍零请求。显式读取入口重新解析 source 时若发现变化，先切 epoch 和准备状态，由该入口决定本次 ReadReason：refresh 保持 refresh，ensureLoaded 使用 initial；不让自动 initial 抢先建立请求。重复 ensureLoaded 不自动重试失败。使用 refresh 才启动新的尝试。

### Pages 状态

~~~text
idle → initial → loaded
               → initial error
loaded → append → 追加成功并更新 cursor
                → nextError，保留 items/cursor
loaded → refresh → 替换为新第一页
                 → error，保留 items/cursor
append 中 refresh → 旧 append 以 superseded 结束 → 新第一页
任意 source 改变 → 清所有旧页 → 新 initial
~~~

重复 append 返回当前 append.future。refresh 已在进行时 loadMore 返回以 ResourceException(busy) 完成的 Future。重复 refresh 返回当前 refresh.future。ensureLoaded 只对应首屏尝试，不被 append 冒充；refresh 接受时就更新最近首屏尝试 Future，失败也保留它，不能在失败刷新后返回之前的成功值。已成功加载且没有下一页时，loadMore 返回以不可变空 List<T> 完成的 Future，不发请求，不修改 items/cursor/phase/error；首屏未成功时以 notReady 完成。到底是正常状态，不增加 noNext 控制异常。

刷新只请求一页并在成功后替换旧页，页游标从新第一页重新建立。下一次 loadMore 从新游标继续。旧追加失败或晚到都不修改新 refresh 的状态。第一次首屏失败时 loadMore 返回 notReady，重试通过 refresh。

页数据保留不可变累计条目快照，不额外保留全部历史页块。公开 items 是不可变快照；一次追加至少需要复制新增结果，平铺 List 的累计复制成本见性能模型。3.0不偷偷按 ID 去重，不加载之前所有历史页。

提交前先校验 nextCursor。空页仍给非空 next、或非空 next == 本次请求 cursor，都是协议 StateError，记录到对应错误字段并以该错误完成 Future，保持旧条目和游标。这只防直接不前进，不声称识别 A → B → A 的任意后端游标环。nextCursor 自身抛错同样保留原错误和堆栈。

## 写入和单值状态机

### Action 互斥

~~~text
run(args):
  closed → Future.error(ResourceException(disposed))
  active write → Future.error(ResourceException(busy))
  接受不可变 args 和当前 execute
  active 指针在通知前安装
  清旧值/错误，publish pending；执行捕获callback
  固定本次业务值或原error/stackTrace
  先撤下本次active/旧写锁，再在alive时publish成功或错误状态
  始终以本次业务值或原error/stackTrace完成Future
  不清listener后来创建的新active
~~~

Action 是一般写入口，没有“读了哪些 Value 就自动回滚”的能力。需要回滚的跨实体业务在 execute 中明确表达，或使用应用层业务事务。

### 独立 RemoteValue 互斥和回退

同一实例全局最多一条已接受写。source/identity 变化也不释放这个写锁；A → B → A 时，旧 A 写未结算前不能接受第二笔写。不同实例没有共享锁，这就是显式共享实例的意义。

~~~text
set/update:
  closed → Future.error(ResourceException(disposed))，不求值 source
  重新 resolve source/identity
  source/identity抛错 → Future.error(原error, 原stackTrace)
  closed / write busy / 无可靠值 → Future.error(对应ResourceException)
  固定当前 source、identity epoch、writer、before
  计算 desired；update函数只调用一次
  idle且desired == before → Future.value(before)，零HTTP
  使当前读失效
  publish 乐观 desired + pending
  执行固定 writer
  固定本次结算结果
  alive时在未跟踪区复核当前source/identity；切源或求值错误更新发布epoch
  复核错误不改写固定writer本次返回值/错误；closed时不再求值source
  先撤下旧写锁
  identity epoch仍相同且alive:
    success → publish canonical 或 ack desired
    failure → publish before 与 error
  identity epoch不同:
    不发布旧值，发布当前来源的pending=false，仍以旧操作自己的值或原错误结算Future
  若新identity等待首次读且alive，在同事务中安排当前读一次
  完成本次旧Future，不清listener后来创建的新active
~~~

所有外部写通过 set/update；value 不公开 setter。写中 refresh/ensureLoaded/accept 返回 busy；已有可靠值时，写入口可以使正在执行的读取失效后开始写。identity 改变时旧显示立即清掉，当前状态 pending 保留，表示这个实例还有已接受写未结算；新的读取意图登记一次，旧写结束后再开始。结算发布前撤旧锁和处理当前needsRead，通知期间新操作不能被旧清理抹掉。

source 改变而 identity 不变时，读取 epoch 递增并拒收旧读；业务值保留。写发布 epoch 不变，固定旧 token 的写正常结算。identity 改变则写发布 epoch 也递增。

旧写释放后，所有仍存活的当前快照都必须清 pending；这包括没有 reader、source 仍抛错及无需读取的情况。若同时启动 needsRead，发布 loading=true、pending=false 的当前来源快照，不回填旧值。

3.0不支持按 identity 并行写、写队列、最后意图合并和自动重试。这个限制使状态和内存上界明确。离开 UI 后已接受写仍结算，dispose 不撤销服务器操作；资源停止 UI 发布。

RemoteValue 失败回退只保证恢复本地 before，不证明服务端未提交。timeout 可能处于未知服务端结果。此时 error 保留，调用方可以显式 refresh 重新确认；不自动重发非幂等写。

## Flutter 公开 API 和生命周期

### 订阅和局部状态

~~~dart
Watch(builder: (BuildContext context) => Widget);

StateBuilder<T>(
  Object? identity,
  required T Function() create,
  void Function(T)? update,
  void Function(T)? dispose,
  required Widget Function(BuildContext, T) builder,
);

StateBuilder<T>.value(
  required T value,
  required Widget Function(BuildContext, T) builder,
);
~~~

Watch 是普通 StatefulWidget，其 State 拥有一个基于 alien_signals preset 的 build effect。Flutter 调用 build 时才同步执行当前 widget.builder，使用底座的跟踪和依赖清理过程；active subscriber 只在这次同步构建里有效，并在 finally 还原。信号失效只请求框架重建，不在普通 effect 刷新中执行 Widget builder。dispose 停止底层 effect，释放这个观察者的依赖。

StateBuilder 的 builder 自动跟踪其中同步读取的 Readable.value（包括 Value 和 Computed），复用 Watch 的 build effect 和底座依赖管理。每次使用当前 widget.builder，在同步构建结束的 finally 中还原 active subscriber；分支变化的旧边由底座清理，卸载停止 effect。因此创建页面本地状态不再需要额外嵌套 Watch，StateBuilder.value 也观察传入对象中的 Readable.value。

create 在 Element/identity 内执行一次；create、update 和 dispose 均不跟踪依赖。update 在同 identity 的 didUpdateWidget 中执行，适配普通对象的当前参数；identity 改变时先拆旧观察订阅，再释放旧对象并重新创建。dispose 回调在对象创建时捕获，不能用新闭包的参数释放旧实例。只有用户明确提供 dispose 才调用它；不强制业务对象继承 Store 或 Disposable。

~~~dart
StateBuilder<Value<int>>(
  create: () => Value(0),
  builder: (context, count) => FilledButton(
    onPressed: () => count.value++,
    child: Text('点击了 ${count.value} 次'),
  ),
)
~~~

Watch 用于观察已经存在的状态，不承担对象创建和释放。

三个 Value 组成的 record 无需三个 disposer。Controller、Timer、外部 subscription 和资源对象需要实际清理，这些清理必须完整显示，不能让普通 ValueBuilder 的便利掩盖外部资源。

StateBuilder 不使 TextEditingController.text 或任意普通字段自动可观察。Controller 的原生监听使用 ValueListenableBuilder/ListenableBuilder；输入值与业务状态同步时展示实际 listener 接线。动画 controller 的 ticker 继续由 Flutter 的原生 State/mixin 管理。

### 资源适配器

~~~dart
QueryBuilder<S, T>.create(
  required S Function() source,
  required FutureOr<T> Function(S, ReadRequest) load,
  required Widget Function(BuildContext, QueryState<S, T>, Query<S, T>) builder,
);
QueryBuilder<S, T>.value(
  required Query<S, T> value,
  required Widget Function(BuildContext, QueryState<S, T>, Query<S, T>) builder,
);

PagesBuilder<S, T, C>.create(
  required S Function() source,
  required FutureOr<List<T>> Function(S, C?, ReadRequest) load,
  required C? Function(S, List<T>) nextCursor,
  required Widget Function(BuildContext, PagesState<S, T, C>, Pages<S, T, C>) builder,
);
PagesBuilder<S, T, C>.value(
  required Pages<S, T, C> value,
  required Widget Function(BuildContext, PagesState<S, T, C>, Pages<S, T, C>) builder,
);

ActionBuilder<A, R>.create(
  required FutureOr<R> Function(A) execute,
  required Widget Function(BuildContext, ActionState<R>, Action<A, R>) builder,
);
ActionBuilder<A, R>.value(
  required Action<A, R> value,
  required Widget Function(BuildContext, ActionState<R>, Action<A, R>) builder,
);

RemoteValueBuilder<S, T>.create(
  required S Function() source,
  Object? Function(S)? identity,
  Seed<S, T>? initial,
  FutureOr<T> Function(S, ReadRequest)? read,
  required FutureOr<T> Function(S, T) write,
  required Widget Function(BuildContext, RemoteState<S, T>, RemoteValue<S, T>) builder,
);
RemoteValueBuilder<S, T>.ack(
  required S Function() source,
  Object? Function(S)? identity,
  Seed<S, T>? initial,
  FutureOr<T> Function(S, ReadRequest)? read,
  required FutureOr<void> Function(S, T) write,
  required Widget Function(BuildContext, RemoteState<S, T>, RemoteValue<S, T>) builder,
);
RemoteValueBuilder<S, T>.value(
  required RemoteValue<S, T> value,
  required Widget Function(BuildContext, RemoteState<S, T>, RemoteValue<S, T>) builder,
);
~~~

builder 三个参数是 context、本次不可变快照和操作实例。惰性列表闭包从快照读取，按钮从实例调用操作；不制造额外 View facade。

所有 Widget 构造器另有 Flutter 标准 Key? key；PagesBuilder 的 C 在类声明中约束为 extends Object。Flutter 原生也导出 Action，因此同时导入 Material 和使用 Oref Action 的文件写 import 'package:flutter/material.dart' hide Action，或使用 Dart import 前缀。

create/ack 拥有实例并在 initState 激活：Query/Pages 调 ensureLoaded().ignore()；RemoteValue 一律调 ensureLoaded().ignore()，没有 read 时也建立source订阅但零HTTP；Action 不自动执行。ignore 只处理启动 Future 的错误，state 仍发布错误；后续显式 await 仍得到该 Future 的值或错误。默认所有参数均为构造时的普通回调，没有 BuildContext 传入业务执行函数。

value 只借用，不能自动激活、刷新、更改配置或释放资源。它替换 value 时只切换订阅。拥有者必须自己启动或提前启动资源。这条规则避免多个消费者各自发请求或各自释放共享对象。

owned adapter 的 didUpdateWidget 更新当前 source、load/read/write、identity 和 nextCursor 配置；initial 仍只初次消费。资源输入 effect 只在激活后存在。资源启动用户函数安排在跟踪构建之外的微任务阶段；首次构建可以看到 pending，HTTP 不在 build effect 的跟踪区执行。已接受 deferred write 即使之后 dispose 仍执行并结算，只禁止向关闭资源发布。

实例配置来自构造参数。若依赖 InheritedWidget，普通页面先在 build/didChangeDependencies 取服务，再作为参数传给资源 adapter；不在 initState 的 source 或异步请求中建立 InheritedWidget 依赖。Flutter 对初始化、订阅替换和释放的边界见 [initState](https://api.flutter.dev/flutter/widgets/State/initState.html) 与 [didUpdateWidget](https://api.flutter.dev/flutter/widgets/State/didUpdateWidget.html)。

组件销毁时先拆观察者，再 dispose 自己拥有的实例；禁止依赖 GC finalizer、每帧遍历 Element 或普通 BuildContext 的隐式缓存位置。

已确认第 6 项：统一采用“创建者拥有，消费者借用”。ResourceScope.create 同样拥有其工厂返回的 Resources，并在卸载时关闭目录；ResourceScope.value 只接入外部目录，由外部拥有者关闭。create 回调返回外部变量表示明确转移所有权，目录关闭后不能在另一次挂载中复用。Resources.use 的借用持续到 callback 的 Future 结束，不增加公开 Lease 或 Owner 类型。

页面卸载先停止 UI 观察。局部拥有资源立即关闭，使读取失效并尝试取消；共享资源只归还借用，最后借用离开后进入有界闲置缓存。已接受写入继续执行并结算原 Future，关闭或会话切换后不再向旧 UI 发布，也不向新会话发布；共享目录保留原实例与写锁直到结算，防止页面重入绕过未完成写入。

### Flutter 调度

信号传播和 effect 排队仍由 alien_signals 完成。Flutter adapter 只为自己的 State 维护一个重建待办标记：正常安全阶段请求重建，锁定构建阶段推迟到安全的微任务或 post-frame 回调；回调再次检查 mounted。它不维护全局活动节点队列、不扫描 Element 树，也不重新给 source 与 UI effect 排优先级。

同一个 State 的重复重建请求可以合并为一项。构建中再次失效和卸载后的回调必须验证；不以第二份全局版本图承诺消除所有额外帧。具体安全阶段和依赖替换由 Flutter adapter 的测试确认，不把框架调度行为称为底座提供的保证。

每个资源默认一个快照通知边界。因此 pending 改变可能重建包含列表的同一个 resource Builder。3.0不宣传自动字段级重建；大 UI 用稳定子组件与显式 Watch/Computed 分开观察。三处细粒度旧观察器与一个新 Builder 的差异必须纳入实际构建次数。

## 共享和资源目录：第 4 项已确认入口

3.0 正面设计库内共享入口，撤回“先只传实例、目录以后再做”的取舍。目标是应用定义一次资源，页面按业务参数获取；查找、创建、共享、借用与回收由库管理。用户已确认本节共享入口设计与第 6 项生命周期规则；示例缓存容量和时长不是固定默认值。

公开概念为 Family、Resources 和 ResourceScope。Family 描述如何按参数创建资源；family(key) 返回惰性的 ResourceRef，不创建实例、不发请求、不永久持有资源。Resources 是明确的应用或会话目录。ResourceScope 在 Navigator 上方接入同一个目录，Builder 内部定位目录，业务函数不接收 BuildContext。

下面完整展示一个模拟资源的定义与两个消费位置，没有应用 Store 或缓存 helper：

~~~dart
final article = Family<int, Query<int, String>>(
  create: (id) => Query<int, String>(
    source: () => id,
    load: (id, request) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return '文章 $id';
    },
  ),
  dispose: (query) => query.dispose(),
);

final sessionIdentity = Value<Object>(Object());
final resources = Resources(
  namespace: () => sessionIdentity.value,
  maxIdle: 64,
  retain: const Duration(minutes: 5),
);

Widget app() => ResourceScope.create(
  create: () => resources,
  child: MaterialApp(
    routes: {
      '/': (_) => QueryBuilder<int, String>.shared(
        ref: article(42),
        builder: (context, state, query) => Scaffold(
          body: Text(state.hasValue ? state.value : '加载中'),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.of(context).pushNamed('/preview'),
            child: const Icon(Icons.preview),
          ),
        ),
      ),
      '/preview': (_) => QueryBuilder<int, String>.shared(
        ref: article(42),
        builder: (context, state, query) =>
            Scaffold(body: Text(state.hasValue ? state.value : '加载中')),
      ),
    },
  ),
);

Future<String> refreshArticle(int id) =>
    resources.use(article(id), (query) => query.refresh());
~~~

第11项已确认：maxIdle和retain必须在应用组装边界显式提供，没有隐藏默认值。64个闲置条目与5分钟只是本例选择。

~~~dart
Resources({
  required Object? Function() namespace,
  required int maxIdle,
  required Duration retain,
});
~~~

maxIdle和retain须非负，否则构造时抛ArgumentError；maxIdle为0或retain为Duration.zero表示不保留闲置缓存。最后借用释放后即可淘汰，但已接受写仍保活至真实结算。只在应用根部配置一次，不要求每个Family重复配置。

Family与Resources在应用组装边界创建一次；每个应用或测试拥有独立目录，不能复用已经关闭的目录。真实HTTP、JSON、权限和业务副作用仍完整写在工厂与资源回调内。

下列合同已随第 4、6、7 项确认，仍须一起验证实现与成本：

- 共享键是 namespace、Family 对象身份、不可变参数的 ==/hashCode。Family 不在每次 build 创建；两个相等 ResourceRef 不反复换订阅。缓存不同会话、不同定义或不同参数的实例互不共享。
- 会话身份使用每次登录/退出产生的新对象，token 不作为目录键。同会话 token 变化由资源 source 决定是否重读，不能为每个消费者各建实例。目录在接受操作与读取结算边界复核身份，不能依赖 source effect 的交付顺序。
- 目录身份不能替代写参数快照。Remote 写使用接受时的 source；普通 Action 需要业务将身份、token 等必要输入放进不可变 arguments。固定 execute 闭包不等于固定其后来读取的全局 auth；库不能自动冻结任意 Dart 闭包或外部客户端。
- namespace 的同步 getter 可以读取现有信号。变化由底座 effect 驱动目录和 Scope，所有已挂载的 .shared 消费者自动释放旧借用、取得新 namespace 的实例并停止显示旧快照；即使 ResourceRef 的定义和参数相等也重新绑定，不要求页面自行加 Key 或等待导航重建。
- Query/Pages/Action/RemoteValueBuilder.shared自动获取与释放借用。共享Query/Pages自动ensureLoaded().ignore()，Action不自动运行；RemoteValue根据自己的读取协议启动，字段视图复用父Query的读取。.create仍是局部拥有，.value仍是对明确持有实例的借用。
- 最后消费者离开后进入有上界的闲置缓存，暂停输入变化造成的自动请求；再次获取先核对最新 source。未完成读可在保留窗口内完成，淘汰时使其失效并尝试取消。
- 已接受写持有同 namespace、同 key 的实例与写锁直到真实结算；不能因为 Widget 消失或容量淘汰创建第二个实例绕过写锁。namespace 改变关闭旧条目、取消读、停止旧 UI 发布，旧写保留原结果结算，新会话获得独立资源。
- maxIdle 限制闲置条目，活跃消费者与未完成写另计。TTL 使用一个最近到期调度，不为每条目创建 Timer，不扫描每帧。闲置缓存必须暂停 source 订阅，不能因为保留 64 个条目产生后台批量请求。
- Resources.use 在调用时解析当前 namespace，持有至 callback 的原生 Future 结束并在 finally 释放。登录导航后重新 use，避免调用导航前借用的旧实例；不新增 Outcome 或自定义 Future。
- Family 管理 Oref 的异步资源。原生资源提供包内的操作保活与输入暂停钩子；不将任意业务对象、服务查找或第二个依赖图塞进目录。测试通过普通 Dart 构造参数组装 fake API/auth 与独立定义，不自动提供全局工厂覆盖。

请求复用成立于同一目录、同一namespace、同一key、source稳定且条目未过期/淘汰的范围。缓存仍有entry、借用计数、闲置LRU与保留数据的内存成本。上一稿Query+Action虽由Family消除通用借还，仍需应用Value、Map与读写协调；当前已确认字段RemoteValue将这项协议收入库。旧291行实现保留为历史全文对照，旧286行草稿不作为成本基线。

外部 Controller/Timer 使用 StateBuilder 的显式 dispose。需要订阅时，Subscription 在创建者边界释放。库内部取消和清理登记不覆盖之前登记；按相反顺序执行，逐个隔离异常，确保剩余资源释放。没有隐藏的公开 Owner 登记机制。

## 完整业务验收

分页验证首屏、追加、刷新、来源切换、错误与游标边界。共享关注验证两个页面共用一份模型和写锁、乐观更新、失败回滚、旧读取失效、登录续接、会话切换与离开页面后的写保活。

示例中的服务、会话、导航、HTTP接线和错误UI必须完整展示。比较应用代码和库实现时分别计账，不用未展开的Store/helper掩盖复杂度。公开用例只保留通用业务模型，不包含本地开发参考应用的源码或名称。

<a id="remote-value"></a>

## Query 字段视图与 RemoteValue（第8–10项已确认）

组合Query+Action仍需要应用自行协调共享乐观值。本轮已确认由库管理同一模型的字段写入，应用不再维护overlay、Map、epoch、owners或回滚代码。第8项确认字段API，第9项确认独立与字段RemoteValue均进入3.0稳定设计目标，第10项确认同父写锁和写优先读取。此前实验定位由本轮确认覆盖；API按本合同实施，发布前须通过验收。

### API：一份模型，一个写锁，字段返回 RemoteValue

~~~dart
extension QueryFields<S, M> on Query<S, M> {
  RemoteValue<S, V> field<V>({
    required V Function(M) select,
    required M Function(M, V) apply,
    required FutureOr<V> Function(S, V desired) write,
  });
  RemoteValue<S, V> fieldAck<V>({
    required V Function(M) select,
    required M Function(M, V) apply,
    required FutureOr<void> Function(S, V desired) write,
  });
}

extension QueryFamilyFields<K, S, M> on Family<K, Query<S, M>> {
  ResourceRef<RemoteValue<S, V>> Function(K) field<V>({
    required V Function(M) select,
    required M Function(M, V) apply,
    required FutureOr<V> Function(S, V desired) write,
  });
  ResourceRef<RemoteValue<S, V>> Function(K) fieldAck<V>({
    required V Function(M) select,
    required M Function(M, V) apply,
    required FutureOr<void> Function(S, V desired) write,
  });
}

RemoteValueBuilder<S, T>.shared(
  required ResourceRef<RemoteValue<S, T>> ref,
  required Widget Function(
    BuildContext, RemoteState<S, T>, RemoteValue<S, T>
  ) builder,
);
~~~

Query 是完整模型的唯一拥有者；field/fieldAck 返回可读写某个 V 的 RemoteValue，不复制一份独立业务数据。select 读字段，apply 以 copyWith 等纯同步操作替换字段，write 只保存这个字段。field 的 write 返回服务器 canonical V；fieldAck 的 write 只确认成功，采用 desired。字段的 set/update 返回原生 Future<V>，没有 Outcome。

Family 上的定义在组装边界创建一次。followed(id) 只是派生 ref；Resources 解析时借用原 Query 条目，再取得该定义的字段视图。它不是第二个 Family 缓存条目，不创建另一个 source effect 或 GET loader。直接实例 field/fieldAck 由该 Query 拥有，Query.dispose 统一关闭视图；value Builder 仍只借用。

字段 RemoteValue 继承父 source、所有权和读写调度，不可另配 source/identity/read/initial。它与独立 RemoteValue 使用同样的 state/set/update/ensureLoaded/refresh，但不是一个拿父 Query 结果做 seed 的独立资源。字段的 accept 检查完整当前 source、父模型就绪、无父读/写，纯同步 apply 后一起更新父模型；否则同步抛相应控制异常。显式 dispose 字段只关闭该视图，不能关闭父 Query 或释放其在途写锁；父仍负责已接受写结算与模型发布。

### 完整业务定义示例

这里用模拟接口展示全部逻辑；完整页面和会话接线见example，实际请求协调由本地HTTP集成测试验证。

~~~dart
class Item {
  const Item(this.id, this.followed);
  final int id;
  final bool followed;
}

var serverFollowed = false; // 模拟服务端状态
final item = Family<int, Query<int, Item>>(
  create: (id) => Query<int, Item>(
    source: () => id,
    load: (id, request) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return Item(id, serverFollowed);
    },
  ),
  dispose: (query) => query.dispose(),
);
final followed = item.fieldAck<bool>(
  select: (item) => item.followed,
  apply: (item, value) => Item(item.id, value),
  write: (id, value) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    serverFollowed = value;
  },
);

Widget followButton(int id) => RemoteValueBuilder<int, bool>.shared(
  ref: followed(id),
  builder: (context, state, remote) => IconButton(
    onPressed: !state.hasValue || state.pending
        ? null
        : () => remote.update((value) => !value).ignore(),
    icon: Icon(
      state.hasValue && state.value ? Icons.star : Icons.star_outline,
    ),
    tooltip: state.error?.toString(),
  ),
);
~~~

示例为单个 Item 的按钮，Resources/Scope 沿用上文完整装配。ignore 仅消费 Future，error 留在 state 并由 tooltip 展示；真实关注版明确处理登录续接、unknown 重读、失效和 SnackBar，不以这里的短例子计账。

### 库内必须完成的协调

1. **所有消费者只认同一模型。** 接受写时，捕获 source/epoch/before，保存 preview=apply(before, desired)，同时发布父模型和各字段视图的状态。详情 Query.value.followed、两个关注按钮立即一致；失败恢复 before，所有视图一起恢复。parent Query.pending 仍表示 GET，字段 loading 跟随它；所有字段 pending 表示父写锁，不偷改 Query.pending 的含义。
2. **同一父模型只接受一笔写。** 不同字段也互斥，忙时返回 busy，既不运行 update/apply，也不发 POST。不同 id 各自独立。空闲且值相等零 HTTP；update 缺字段值返回 notReady，不执行变换。set 不隐式读取，至少需要父模型；字段未知但父模型存在时，可明确 set 一个值，失败回到原模型（包括未知字段）。
3. **写优先于旧读。** 有 before 时允许在刷新 GET 未结束时开始写；旧 GET 立即以 superseded 结束并尝试取消，之后不能覆盖 preview/提交值。写期间父和字段的 ensureLoaded/refresh 一律 busy，零 GET。不排队等待一次刷新，也不保存一个会在写后偷偷执行的刷新意图。没有 before 时不接受写。
4. **固定写输入与发布资格分开。** writer 使用接受时的 source，页面离开不取消已接受写；同 key 再进入仍见原锁。source/namespace 改变后旧写仍返回真实成功或错误，但不向新来源发布或回滚。旧 namespace 条目退役后不允许借全局 auth 自动请求新来源，任何自动读也先核对目录归属，不能依赖 effect 顺序。
5. **source 改变仍继承 Query 合同。** 字段不另造 identity。包括 token 在内的完整 source 改变就清掉旧模型、旧读失效。若同一 Query 仍有旧写，等它结算后才为最新 source 启动一次读取；这次 source 驱动的读取与手工 refresh 排队不同。namespace 更换则是新条目，可独立开始读取。独立 RemoteValue 的 identity 提取与 token 保值合同继续存在，两者明确区分。
6. **GET 与字段错误分别保管。** Query.error 只表达读取错误，字段写失败不污染它。select 抛错只让该字段 hasValue=false/error，父 GET 与其它字段仍成功；select 不触发重读。字段 error 优先显示当前投影失败，其次保留本字段最近写错误，否则显示父读取错误；本字段新写开始或父 GET 成功清掉本字段旧写错误。busy/notReady/sourceChanged 等控制异常不覆盖业务错误。所有原错误和堆栈经原生 Future 交付。
7. **投影与 Future 也去重。** select/apply/update 为纯同步回调；select 按父模型版本缓存值或异常，不能从 effect 逃逸。字段同一读尝试缓存一个 Future<V>，同字段反复 ensure/refresh 返回同一个 Future，不是每次新建 then；父 Future<M> 与字段 Future<V> 类型不同，本来就不承诺相同对象。投影 unknown 的失败 Future 也缓存，重复构建不请求，明确 refresh 才重读。
8. **提交值更新读取缓存。** 字段写成功后，Query.ensureLoaded 返回最新提交模型的缓存 Future，字段返回最新字段值，不能还返回上一次 GET 的旧模型。失败恢复 before 与其模型缓存；未失效的读取错误仍保留在 Query.error，成功字段写不能冒充整份模型已重新 GET。字段 accept 同样更新父缓存。这个能力只由关联写协议使用，不开放任意 setData。
9. **同步准备完成后再发 HTTP。** 先建立父级共享重入守卫、核对模型和 source、只调用一次 update 与 preview apply。同父另一字段的重入也返回 busy，不能只有每个视图自己的准备锁。回调抛错则不发 HTTP；回调改变来源/关闭实例按既有 Remote 规则处理。ack 成功直接采用已算好的 preview；canonical 成功用 before 和返回 V 再 apply。canonical apply 失败意味着服务端可能已保存：本地回退并交付原错误，禁止自动重试。回调须遵守 select(apply(model, v)) == v，并且只修改所属字段。
10. **生命周期、通知与内存有成本。** 父 entry/写锁保活至 writer 真正结算；lease 消失不能绕过锁。字段 view/缓存按父 entry 和字段定义持有，父淘汰统一关闭，不另设 TTL、Timer、LRU。一个父写最多保留 before 与 preview 两个模型引用；copyWith 可共享子对象但仍会分配新模型。先在 batch 内完成所有内部状态，再通知订阅者，异常不能遗留 pending 或丢失 Future 结算。长期不结束的 writer 会继续占用内存，maxIdle 不限制它。

### RemoteValue 现在是什么

它表示“可以把远端值改成 desired 的状态”。来源有两种：独立值自己提供 read/write；Query 字段视图借父模型读取、提供 select/apply/write。两者共同提供 set/update 的乐观显示、busy、回退与 Future，不能再把共享乐观关注归类为普通 Action。

独立设置的全部读写定义仍可直接写：

~~~dart
var stored = false; // 模拟一个独立设置
final setting = RemoteValue<String, bool>.ack(
  source: () => 'darkMode',
  read: (key, request) async => stored,
  write: (key, value) async { stored = value; },
);
~~~

独立设置由 .create/.ack Builder 或明确创建者拥有，必须按现有所有权规则释放。字段没有独立 Seed、重复读取或布尔 overlay。Action 继续用于保存表单、发送邮件、上传等一次动作；不自动给任意副作用附加乐观状态。

不选择 RemoteValue<Source,Item>.ack 的理由：follow POST 只保存 followed，却让 set(Item) 看起来可以保存整份模型，ack 还可能把未发送的其它字段留作“已确认值”。字段 API 将写参数限制为 bool，不提供这种错误暗示。不引入公开 Lens/Store/事务对象，也不承诺跨实体、列表成员或多字段并发合并。

### 回验与已确认的成本取舍

完整页面、登录守卫与配套应用装配应一起验收，不以单行按钮调用作为全部成本。按钮会在每次 await 后核对当前页面/id/身份；恢复失败仍可登录，匿名有效会话可写。首次 unknown 明确 refresh 一次；写失败已经回滚时再点使用已知值，不因 error 自动 GET 后反转服务端状态。token 切换造成的 notReady 不隐式重试，等待新读或下一次点击。

第8–11项均已确认：字段API、独立与字段RemoteValue稳定设计、同父串行写/写优先、根目录显式缓存策略。此前第3项的实验定位由第9项覆盖，1–7其余确认不变。接受token变化重新读取及会话过渡额外GET，不增加暂停/恢复API。完整模型缓存比旧bool map更大；详情乐观修改会重建父Query观察边界，不能宣称只重建星标。退出过渡的公开/匿名新namespace仍可能各GET一次。这些成本保留在实施验收中。

## 性能和请求成本

以下是结构预算与实现验收条件，不是速度跑分。

| 成本 | 3.0预算 |
| --- | --- |
| Value | 一个底层SignalNode与用户API包装；写入比较沿用identical |
| Computed | 正常路径一个底层ComputedNode；2.3.5失败路径可增加底座重试依赖与link；不承诺闲置零缓存 |
| 同步批处理 | 复用alien_signals的startBatch/endBatch与effect队列，无第二个依赖图或队列 |
| Flutter | 每个观察边界一个底层effect与State的待办标记；每帧不扫描全树 |
| Query | 一个快照信号、一个输入effect、一个有效读操作 |
| Pages | Query 的调度成本，加不可变累计列表和游标；不额外保留全部页块 |
| Action | 一个快照节点、至多一笔写 |
| 独立 RemoteValue | 一个快照信号、一个输入effect、至多一笔写及一个读取意图 |
| Query字段RemoteValue | 复用父entry/source/read，增加字段view/投影缓存与父写槽；无第二个源effect/GET/TTL |
| 输入求值 | 操作接受和读提交各复核source；依赖变化由底座effect批处理，不承诺重入时每batch一次 |
| 共享目录条目 | 每个条目一个目录记录、借用计数与闲置LRU登记；ref是轻量描述符，不复制业务状态 |
| 共享目录观察 | 一个底座namespace观察边界与Scope通知；不建立第二个响应引擎 |
| 共享缓存 | 闲置保留条目受maxIdle与retain限制；活跃UI与未完成写另计，输入订阅在闲置时暂停 |
| Future | 每条已接受操作一个原生Future/Completer；无Outcome或自定义Future句柄分配 |

累计 n 条目的平铺不可变 List 在追加时有 O(n + 新页大小) 的复制；固定页大小滚到多页会有累计复制成本。3.0优先普通 List 的直观 API。实现验收同时比较页块不可变视图方案；只有真实大列表的复制或布局成本显著时再采用，不能把复杂分段集合当免费优化。

| 场景 | 有效请求预算 |
| --- | --- |
| 普通 rebuild 100 次、相同 source | 0 次额外请求 |
| 首次分页接入 | 1 次首屏读取 |
| append 进行中连续 loadMore 20 次 | 1 次追加 |
| refresh 进行中连续 refresh 20 次 | 1 次有效刷新 |
| 刷新已加载十页的列表 | 1 次第一页读取 |
| 输入更换 | 新输入 1 次；旧请求尝试取消 |
| 关注 read 复用详情 Query | 详情 HTTP 共 1 次 |
| 关注 update 被接受 | 1 次写；无自动读回或重试 |
| pending 内点击 20 次 | 1 次写，其余以 busy 结束 |

没有请求级 abort 时，输入变化/刷新可能让一条过期 HTTP 与新 HTTP 暂时并行。只统计有效请求不能隐藏这部分带宽；性能测试必须同时记录物理 HTTP 数和有效操作数。

搜索防抖是可选输入策略，3.0应用在输入 Value 前使用 Timer，并完整释放 Timer。库不默认为任意 source 加延迟。需要通用 DebouncedReadable 时通过第二个真实场景再决定。

## 必须通过的验证矩阵

| 类别 | 关键案例 | 必须成立的断言 |
| --- | --- | --- |
| 信号适配 | 条件从 A 改读 B | 底座完成本次跟踪后清理A旧边；无Oref镜像依赖图 |
| 信号适配 | effect/Subscription停止、Computed仍被用户保存 | 停止观察后不再回调；依赖和缓存行为与底座一致 |
| 信号适配 | identical结果与==相等但不同实例 | 通知与底座identical语义一致，不偷偷深比较 |
| 信号适配 | batch中读取/抛错、嵌套batch | finally结束底层batch，行为与底座一致，不跨await |
| 信号适配 | subscribe的listener抛错、同步重入 | Oref未跟踪/登记Zone包装生效；不扩成任意底座effect的全局队列隔离 |
| 输入 | 直接递归资源操作 | 局部重入守卫拒绝，不以额外全图环检测代替业务输入约束 |
| 信号适配 | computed错误、effect内写、循环输入误用 | 不新增与底座不同的缓存或通用写禁令；不声称底座未提供的环拒绝 |
| 信号适配 | 2.3.5嵌套computed错误、a→b→a和批量effect | 保留底座错误恢复与队列修复；适配层不绕过底座重试依赖 |
| Flutter | sibling、嵌套、构建抛错、惰性builder | active subscriber同步作用域finally恢复；每个资源使用自己的不可变快照 |
| StateBuilder | builder 读取 Value/Computed，分支切换和 identity 更换 | 自动跟踪与动态拆订阅；更换对象前拆旧观察者 |
| StateBuilder | create/update/dispose 读取 Readable.value | 不建立 builder 的观察依赖，生命周期回调保持不跟踪 |
| Flutter | parent 更新 callback | 下次操作与构建使用新回调 |
| Flutter | source 改变而 Key 不变 | 自动拒收旧结果 |
| Flutter | owning/borrowed 切换 | 恰好一次 own disposal；borrow 不释放 |
| Flutter | build中失效、重复待办、卸载后回调 | mounted检查、正确请求重建、不漏更新；不依靠全局版本图 |
| 资源 | source/UI订阅顺序变化、普通Value与资源同时读取 | 不依赖全局阶段优先；显式操作/读提交复核source，旧epoch不发布 |
| 资源 | 通知抛错或结算期间重入 | finally保障已接受工作的安排/Completer结算，不把通知错误当业务失败 |
| 共享目录 | 同定义同参数的两个路由、反复构建相等ref | 同一目录只有一实例/当前读取；相等ref不换订阅或重复HTTP |
| 共享目录 | namespace变更而ref不变、同用户退出再登录 | 自动换实例与快照；旧读失效、旧写按固定参数结算 |
| 共享目录 | 最后消费者离开、TTL到期、LRU淘汰 | 输入自动读取暂停；闲置上界生效；请求取消只作用于本次操作 |
| 共享目录 | 最后消费者离开但写未完成、随后重入同key | 保留原实例/写锁到结算；不能新建第二笔同key写 |
| 共享目录 | use跨await、目录关闭或会话切换 | finally释放借用；已接受写完成；旧借用不对新会话发起工作 |
| Query | repeated ensure/refresh | 相同有效操作 Future identical |
| Query | A → B → A、同步 callback throw | 只有当前 generation 可发布 |
| Query | listener 中 dispose 或换输入 | 旧 start/finally 不污染新状态 |
| Query | 首屏失败后重订阅 | 不自动重试；refresh 可重试 |
| Pages | append 未结束就 refresh | 旧追加以 superseded 结束，新第一页正确 |
| Pages | 追加失败/相同游标/空页 | 条目保留，可重试，防无限页 |
| Pages | 已成功加载且hasNext=false后重复loadMore | 返回不可变空List、零HTTP，items/cursor/phase/error不变 |
| Pages | 相同数量的新内容 | 列表快照更新，delegate 重建 |
| Action | busy、dispose、同步异常 | 不新增写；已接受 Future 正常结算 |
| Action | 新run、成功null、失败 | 旧值/错误按合同清除；hasValue区分合法null；原错误/堆栈保留 |
| Future | source/loader/writer/execute/update同步throw或异步error | 只经Future交付原错误与堆栈；accept按同步合同抛错 |
| Future | 自动读取失败、显式调用失败、过期、拒绝 | 自动启动ignore；显式调用按原生错误规则；控制异常reason准确 |
| Future | 已失败的ensureLoaded、进行中合并、refresh | 缓存/合并返回相同Future；refresh建立新尝试，不自动重试 |
| Remote | 登录导航后立即 update | 再取当前输入，不使用旧 token |
| Remote | 新会话没有可靠 seed | notReady，不能反转旧用户值 |
| Remote | token 变、identity 不变 | 旧写按旧快照结算，新写用新 token |
| Remote | identity A → B → A | 旧写锁保留，旧结果不发表 |
| Remote | 外部 accept 与 pending 冲突 | busy，不猜测覆盖顺序 |
| Remote | canonical/ack/timeout | 正确采纳或回退，无自动非幂等重试 |
| Query字段 | GET中写、写中refresh、跨字段重入/busy | 废弃旧GET，零新增读取；父级准备锁与写锁不会被其它字段绕过 |
| Query字段 | 乐观/回退/提交、canonical apply失败 | 父模型与各字段一致；保留原错误，无自动写重试 |
| Query字段 | select未知、重复ensure、写后ensure | 父GET不失败；投影值/错误/Future缓存，无重读循环，不返回提交前旧模型 |
| Query字段 | source/token/namespace改变、字段dispose、父淘汰 | 继承Query换源清值，旧写真实结算；旧entry禁止自动读取新账号，锁保活至结算 |
| 真实契约 | 后端 followed 缺省、有效匿名 | 缺省保持未知；匿名权限不被API设计擅自改变 |
| 成本 | 1000 条目、十页、20次重复调用 | 同时记录分配/重建/物理请求 |
| 成本 | 大量闲置资源 | 不因每帧刷新付费，拥有者清理可验证 |

这张表是行为与成本验收矩阵，实际执行证据以当前 test/、example/test/ 和下述验收记录为准。行为测试不能替代分配、堆内存或帧耗时测量；未测项目不作性能结论。旧版探针不能作为新协议的实现证据。

## 替代方案和取舍

| 方案 | 优势 | 本设计的取舍 |
| --- | --- | --- |
| 继续以 hooks 为入口 | 小型局部示例短 | 状态创建/参数变化规则分散，完整业务仍写执行协议 |
| Provider 和默认 Container | 大量共享查询身份与覆盖成熟 | 3.0 设计专门的资源目录与一次 Scope 接入；业务依赖仍使用普通 Dart 参数 |
| 普通 Store + 信号 | 任意业务结构清楚 | 不强制 Store；协议通过独立资源统一，业务类仍可使用 |
| 一个万能异步对象 | 表面类型少 | 分页、写入与单值回退需要不同状态机，分开公开 |
| 通用自动乐观事务 | 页面可能很短 | 异步外部写/嵌套与回滚冲突代价高；只支持独立值和父模型字段，不做通用事务 |
| 专用资源 Builder | 页面可完整内联请求/UI | 真实复用成本在库内明确列出，避免 View facade 和 Owner 链 |
| 重写信号内核 | 可以自行规定全部传播合同 | 没有性能或功能证据支持这项成本，撤回；继续复用alien_signals |

3.0沿用 alien_signals，不重写其依赖图、computed 或传播内核。API 重设与底座重写是两项不同工作，前者无需引入后者。Oref 的增量只包含公开表面、资源协议与 Flutter 生命周期适配；以真实重建、分配和请求数验证这些增量的成本，不用计数器示例或未测的“最快”作为替换底座的理由。

## 实现顺序和讨论决策

已确认：响应底座继续使用 alien_signals，并评估最新已发布稳定版本，不固定旧 lock。当前 3.0 基线为 2.3.5。Value、Computed、Subscription、batch 是薄适配；信号变化判断沿用identical，资源source参数独立使用==。不自研第二套信号内核。

已确认：StateBuilder.builder 自动观察 Readable.value，合并创建一次与观察；create/update/dispose 保持不跟踪。Watch 用于已有状态；普通字段和原生 Controller 仍使用各自的监听方式。

已确认第 4 项：共享采用 Family、Resources、ResourceScope 与 Builder.shared，按定义和参数复用资源，支持会话隔离及有界缓存；不要求逐层传递实例。示例 64 条、5 分钟不作为固定默认值。拥有权与在途操作寿命已随第 6 项确认。

已确认第 5 项：Query、Pages、Action 为稳定资源模型，输入采用同步 source；资源 Builder 的参数统一为 context、不可变 state 快照与 resource 操作实例，不引入额外 View facade。

已确认第 6 项：create 拥有并释放，value 只借用，shared 自动借还；ResourceScope 遵循同样的 create/value 所有权规则。最后借用离开后进入有界闲置缓存并暂停输入监听；淘汰使读取失效，已接受写继续结算。Resources.use 借用持续到 callback Future 结束，会话切换隔离旧状态与旧结果。

已确认：所有异步操作使用原生 Future<T>，不增加 Outcome 或自定义 Future 句柄。完整例子、错误消费责任和 ActionState 的公开字段已同步。

已确认第 7 项：同源进行中读取合并，换源使旧读取失效；分页刷新优先于追加，已成功加载且无下一页时 loadMore 返回不可变空列表、零请求。同一实例写入忙碌时拒绝新操作，不合并、不排队、不自动重试。业务错误保留原对象与堆栈并进入对应错误状态；ResourceException 控制异常不覆盖业务错误。调用方只忽略明确预期的 busy/sourceChanged/superseded，disposed 结合调用方寿命判断；只通过 state 展示错误时可以明确 ignore 操作 Future。

已确认第8项：采用Query/Family.field与fieldAck返回RemoteValue字段视图；共享乐观值、回滚、读写协调和保活由库管理，业务声明select/apply/write。

已确认第9项：独立RemoteValue与字段视图一起纳入3.0稳定设计目标，发布前必须通过实现验收。此项覆盖此前第3项的实验定位；开发实现已提供该能力，不等于稳定版本已经发布。

已确认第10项：同父模型全部字段共用写锁，写开始废弃旧读，写中refresh/ensureLoaded返回busy、零新增读取；不同模型独立。不引入字段并发合并、排队或自动写重试。

已确认第11项：Resources在应用根部显式配置maxIdle与retain，无隐含默认值，不要求每个资源重复配置。接受token变化重读及会话过渡额外GET，不新增暂停/恢复API。

1. 在现有alien_signals上完成薄适配与Query/Action/RemoteValue纯Dart协议，包括字段视图、父写锁、回滚、Future身份与source失效；不重写底座。
2. 实现Family/Resources，验证同key复用、namespace隔离、显式缓存配置、TTL/LRU和已接受写保活。
3. 接入Watch/StateBuilder及Query/Action/RemoteValue Builder与Scope，验证拥有/借用、最新回调、导航和页面退出。
4. 打通完整通用关注与认证示例，验证双页共享、读写竞争、失败回滚、账号切换，记录物理HTTP与实际重建，分配和内存测量须注明环境与边界。
5. 完成Pages/PagesBuilder及完整文章分页验证，再完成其余3.0文档和迁移说明；按真实成本评估可选页块视图与调试扩展。

核心决策1–11已确认，第9项覆盖此前第3项的实验定位。字段RemoteValue承担共享乐观值、回滚和读写协调。用户已授权按此合同完成实现和测试；验收必须覆盖生命周期、会话隔离、读写竞争及明确的成本边界。缓存容量/时长必须显式配置，64条和5分钟仍为示例；页块视图、调试工具与DebouncedReadable按真实收益评估，不新增核心决策。

3.0为不兼容的全新主版本，旧入口、hooks、集合拦截、analyzer插件和DevTools扩展移除。当前开发版本尚未发布；README与测试反映实际实现，本RFC保留完整协议与设计取舍。

## 开发验收记录（2026-10-16）

当前版本为3.0.0-dev.1，尚未发布。公开入口、资源协议与Flutter适配均已落盘；旧hooks、集合拦截、analyzer插件与独立测试包、DevTools扩展应用及旧依赖已移除。公开示例采用通用模拟数据，私有应用引用不进入仓库、文档站点或发布清单。

执行环境：Flutter 3.47.6 stable、Dart 3.13.5、alien_signals 2.3.5。

- 库测试148项通过，覆盖信号、四类资源、字段视图、目录、Flutter生命周期与4项真实本地HTTP集成。
- 示例测试13项通过，覆盖双页乐观关注/回滚、登录续接与取消、身份/页面/条目守卫、unknown不写，以及分类分页、追加重试、刷新和详情返回。
- dart analyze与格式校验通过；Flutter Web release构建通过；中英文文档站点构建通过。
- 同一共享项的20次并发读取实际只有1次GET；写入busy拒绝不新增GET/POST。旧GET被写入替代后，其结果不覆盖提交值，请求级abort不关闭共享客户端。
- 同source连续100次Widget重建不新增读取。分页1000条/10页，每次20个调用加入同一Future，总共10次loader调用；刷新仅增加1次并回到100条第一页。这里是请求次数与行为验证，不是速度跑分。
- 最后消费者离开后暂停source；在途写保活、TTL/LRU、0容量/时长、namespace切换与ABA、回调异常和取消重入都有独立回归。

验收未对分配、峰值堆内存、首帧或帧耗时给出跑分，也未迁移或调用私有应用。模拟服务计数与真实HTTP计数明确区分。文档首页保留既有Three.js大chunk构建提示；Flutter Web构建有未使用CupertinoIcons字体提示，示例使用MaterialIcons。

## 外部依据

版本依据为 [pub.dev 实时元数据](https://pub.dev/api/packages/alien_signals)与 [2.3.5 发布说明](https://github.com/medz/alien-signals-dart/releases/tag/2.3.5)。响应合同已对照校验发布哈希后的 [2.3.5 preset](https://github.com/medz/alien-signals-dart/blob/2.3.5/lib/src/preset.dart)、[surface](https://github.com/medz/alien-signals-dart/blob/2.3.5/lib/src/surface.dart)和 system 源码。旧 2.3.2 与相邻 2.3.4 checkout 仅用于比较，不作为 3.0 版本约束。已运行底座边界、嵌套错误恢复和 batch 队列的临时探针；这些历史探针不作为3.0实现证据；当前行为测试记录另列，性能跑分仍未进行。

同步输入 record 的比较遵循 [Dart records 的值相等规则](https://dart.dev/language/records)，字段本身仍须有适合的相等语义。Future 的错误消费和链式回调边界遵循 [Dart Future API](https://api.dart.dev/dart-async/Future-class.html)；本设计直接返回原生 Future，不增加网络取消保证。读取取消由 ReadRequest 和传输客户端协作表达。

请求级取消需要传输客户端配合，具体例子见 [Riverpod 的取消说明](https://riverpod.dev/docs/how_to/cancel)。本设计选择第一页替换的分页刷新预算；[TanStack 的无限查询说明](https://tanstack.com/query/latest/docs/framework/react/guides/infinite-queries)采用不同的历史页刷新策略，两者是数据和成本取舍，不作为速度优劣的证据。
