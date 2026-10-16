# 快速开始

**本指南对应尚未发布的开发版本 3.0.0-dev.1。** pub.dev 现有版本使用不同 API。
评估 3.0 时使用源码 checkout；其他项目通过指向该 checkout 的 path dependency 引用。
先在仓库根运行 `flutter pub get`。需要 Dart 3.13+ 和 Flutter 3.47+。

## 一个包，两个完整入口

业务与纯 Dart 资源测试导入 `package:oref/oref.dart`，该入口没有 Flutter 导入。
页面导入 `package:oref/flutter.dart`，包含相同 API 及 Flutter 适配器。
当前包的依赖解析仍需要 Flutter SDK。
Material 也导出 Action；同时使用 Oref Action 时隐藏 Flutter 的 Action，或使用导入前缀。

## 局部状态

```dart
import 'package:flutter/material.dart' hide Action;
import 'package:oref/flutter.dart';

class Counter extends StatelessWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) => StateBuilder<Value<int>>(
    create: () => Value(0),
    builder: (context, count) => FilledButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    ),
  );
}
```

StateBuilder 只创建一次 Value，并自动观察 builder 中的读取。普通父组件重建不会重建
Value。已有状态使用 Watch。继续阅读[局部状态](./local-state.md)。

| 需求 | API |
| --- | --- |
| 读取一份远端结果 | [Query](./query.md) |
| 游标分页 | [Pages](./pages.md) |
| 显式提交动作 | [Action](./action.md) |
| 乐观修改远端值或模型字段 | [RemoteValue](./remote-value.md) |
| 跨路由复用实例 | [Family 与 Resources](./sharing.md) |

资源是普通 Dart 对象，构造时不请求。拥有型和共享型 Flutter Builder 挂载后启动读取；
value 只借用外部对象。源码中的 `example/lib/shared_follow.dart` 提供完整可运行示例。
另见 [Flutter 生命周期](./flutter.md)和[错误与取消](./errors.md)。
