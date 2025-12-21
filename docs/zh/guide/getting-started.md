# 快速开始

## 安装

```bash
flutter pub add oref
```

或在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  oref: any
```

## 第一个 Signal

```dart
final count = signal(context, 0);

Text('Count: ${count()}');

count.set(1);
```

## Computed

```dart
final count = signal(context, 2);
final doubled = computed(context, (_) => count() * 2);

Text('Doubled: ${doubled()}');
```

## Effect

```dart
final count = signal(context, 0);

effect(context, () {
  debugPrint('count = ${count()}');
});
```

## 使用 SignalBuilder 限定重建

当你只希望局部重建时，可以用 `SignalBuilder`：

```dart
SignalBuilder(
  builder: (context) {
    final count = signal(context, 0);
    return Text('Count: ${count()}');
  },
);
```

## Flutter 示例（来自 example 应用）

::: code-group

<<< ../../../example/lib/main.dart#counter-section [Counter + computed + writableComputed]

<<< ../../../example/lib/main.dart#effect-batch-section [Effect + batch]

<<< ../../../example/lib/main.dart#untrack-section [untrack()]

:::

下一步：**核心概念**。
