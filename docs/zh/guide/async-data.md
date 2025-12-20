# 异步数据

`useAsyncData` 用来管理加载、成功与失败状态。

```dart
final query = signal(context, 1);
final result = useAsyncData<Map<String, dynamic>>(
  context,
  () async {
    final id = query();
    // 在这里请求数据
    return {'id': id};
  },
  defaults: () => const {},
);
```

使用 `when` 渲染：

```dart
final view = result.when(
  context: context,
  idle: (data) => Text('Idle: $data'),
  pending: (_) => const CircularProgressIndicator(),
  success: (data) => Text('Loaded: $data'),
  error: (err) => Text('Error: ${err?.error}'),
);
```

刷新：

```dart
await result.refresh();
```
