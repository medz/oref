# 局部状态

Value 保存同步值，Computed 惰性计算派生值并追踪自己的依赖。
在 Watch 或 StateBuilder.builder 中读取 value 建立观察；peek 不订阅调用者。

```dart
import 'package:oref/oref.dart';

void main() {
  final price = Value(12);
  final quantity = Value(2);
  final total = Computed(() => price.value * quantity.value);
  final subscription = total.subscribe(() => print(total.peek()));
  try {
    batch(() {
      price.value = 15;
      quantity.value = 3;
    });
    print(total.value); // 45
  } finally {
    subscription.dispose();
  }
}
```

## 集合与相等性

普通值沿用底座的 identity 比较；资源 source 输入单独使用 Dart ==。
集合应替换为新的不可变实例：

```dart
final ids = Value<List<int>>(const [1]);
ids.value = List<int>.unmodifiable([...ids.value, 2]);
```

原地修改 List/Map 不会通知观察者。简单格式化或只使用一次的 length 通常无需 Computed。

## 订阅与批处理

subscribe 登记时不执行 listener。后续 listener 在未跟踪环境执行，异常交付登记时的
Zone。创建者负责释放返回的 Subscription。Value/Computed 不要求公开 dispose；
原生 Controller 和外部订阅仍需清理。

batch 只合并同步修改，回调抛错也会结束底层批次，不提供回滚，也不包含 await 后的操作。
Computed 根据本次分支动态更换依赖。

## Flutter 接入

Watch 观察已有状态；StateBuilder 合并一次创建与观察，可显式 update/dispose 普通对象。
它也可返回 record，无需继承 Store。身份变化、借用和原生 Controller 接线见
[Flutter 生命周期](./flutter.md)。
