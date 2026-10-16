# Action

Action 表达保存表单、上传等显式操作，只在 run(arguments) 时运行。
构造、挂载 ActionBuilder 或订阅都不执行。
同时导入 Material 与 Oref Action 时使用 `hide Action` 或导入前缀。

```dart
ActionBuilder<String, String>.create(
  execute: (name) async => 'Saved $name',
  builder: (context, state, action) => Column(
    children: [
      FilledButton(
        onPressed: state.pending ? null : () => action.run('Ada').ignore(),
        child: Text(state.pending ? 'Saving…' : 'Save'),
      ),
      if (state.hasValue) Text(state.value),
      if (state.error != null) Text('${state.error}'),
    ],
  ),
)
```

接受操作时固定不可变 arguments。需要账号身份、token 时把它们一起传入；异步函数稍后再读
全局认证状态不会自动保留原会话。

同一实例最多接受一笔写；忙碌时新调用以 ResourceReason.busy 失败，不合并、不排队。
新操作清掉旧 value/error，再设置 pending；完成后发布结果或原业务错误。
hasValue 区分合法 null 结果与没有结果。

需要导航或后续业务时正常 await 并处理错误，await 后核对页面和会话是否仍有效。
示例明确 ignore，因为 builder 会显示错误。

dispose 禁止新工作和状态发布；已接受写继续执行，以原结果或原错误结算 Future。
共享动作使用相同的[目录规则](./sharing.md)。乐观修改值使用 [RemoteValue](./remote-value.md)。
