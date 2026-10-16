# Flutter 观察与所有权

导入 `package:oref/flutter.dart` 同时获得核心 API 与 Flutter 适配器。
Watch 观察同步 builder 中的 Readable.value；StateBuilder 合并按 identity 一次创建和观察。
只有 Flutter 构建时执行 builder，信号传播只请求重建。

## StateBuilder

create 在 Element/identity 内只执行一次；update 将新普通参数应用到同一对象。
identity 改变先拆观察，再释放旧对象并创建新对象。disposer 在创建时捕获，不会拿新闭包的参数
释放旧对象。create/update/dispose 均不跟踪依赖。StateBuilder.value 只借用。

Value/Computed 不需要 dispose；资源、订阅、Timer 和原生 Controller 要明确清理。

## 资源 Builder

QueryBuilder、PagesBuilder、ActionBuilder、RemoteValueBuilder 的参数统一为
(context, 不可变 state, 操作 resource)。惰性闭包捕获快照，事件从 resource 调操作。

| 构造器 | 职责 |
| --- | --- |
| create / RemoteValueBuilder.ack | 拥有实例，在微任务启动读取，卸载释放。 |
| value | 只观察，不激活、不换配置、不释放。 |
| shared | 从 ResourceScope 借用、启动读取、卸载归还。 |

Action 从不自动执行。无 reader 的 RemoteValue 也会激活 source/seed，但零 HTTP。
拥有型 Builder 更新时更换 source 与执行回调，再核对输入；相同输入不重读，initial 不重复消费。
已接受操作继续使用接受时的回调。释放或归还前先停止观察。

依赖 InheritedWidget 的服务先在页面 build/didChangeDependencies 取出，再作为普通参数传入。
异步业务函数不接收 BuildContext，await 后操作 UI 前检查 context.mounted。

## 原生 Controller

Controller 属性不会自动成为 Readable。需要同步业务值时使用原生 listener，完整清理如下。
片段导入 Material 与 Oref Flutter 入口。

```dart
class NameEditor extends StatefulWidget {
  const NameEditor({super.key});

  @override
  State<NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<NameEditor> {
  final controller = TextEditingController();
  final name = Value('');

  @override
  void initState() {
    super.initState();
    controller.addListener(_sync);
  }

  void _sync() => name.value = controller.text;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(controller: controller),
      Watch(builder: (_) => Text('Entered: ${name.value}')),
    ],
  );

  @override
  void dispose() {
    controller.removeListener(_sync);
    controller.dispose();
    super.dispose();
  }
}
```

资源快照通知可能重建整个 builder，包括 pending 变化。Oref 不承诺自动字段级过滤；
真实 UI 有成本时使用稳定子组件和明确的 Watch 边界。
