# 表单校验 + 异步保存

这个示例把 `.set(...)`、`computed`、`effect` 和 `useAsyncData` 组合在一起。

## 模型与校验

```dart
final name = signal(context, '');
final email = signal(context, '');
final dirty = signal(context, false);

final isValid = computed<bool>(context, (_) {
  final n = name().trim();
  final e = email().trim();
  return n.length >= 2 && e.contains('@');
});

final canSubmit = computed<bool>(context, (_) {
  return dirty() && isValid();
});
```

## 异步保存

```dart
final submit = useAsyncData<String>(context, () async {
  await Future.delayed(const Duration(milliseconds: 600));
  return 'Saved ${name()} <${email()}>';
});
```

用 `effect` 追踪保存结果：

```dart
final lastSaved = signal(context, 'never');

effect(context, () {
  if (submit.status == AsyncStatus.success) {
    lastSaved.set('just now');
  }
});
```

## UI 接线

```dart
TextField(
  onChanged: (value) {
    name.set(value);
    dirty.set(true);
  },
  decoration: const InputDecoration(labelText: 'Name'),
);

TextField(
  onChanged: (value) {
    email.set(value);
    dirty.set(true);
  },
  decoration: const InputDecoration(labelText: 'Email'),
);

SignalBuilder(
  builder: (context) => ElevatedButton(
    onPressed: canSubmit() ? () => submit.refresh() : null,
    child: const Text('Save'),
  ),
);

SignalBuilder(
  builder: (context) => switch (submit.state) {
    AsyncDataSuccess(value: final msg) => Text(msg),
    AsyncDataError(error: final err) => Text('Error: $err'),
    AsyncDataLoading() => const Text('Saving...'),
    _ => const SizedBox.shrink(),
  },
);
```

这个模式把校验放在 `computed`，写入通过 `.set(...)`，
异步处理用 `useAsyncData`，并用 `SignalBuilder` 驱动 UI。
