# Async Data

`useAsyncData` helps manage loading, success, and error states for async work.

```dart
final query = signal(context, 1);
final result = useAsyncData<Map<String, dynamic>>(
  context,
  () async {
    final id = query();
    // fetch data here
    return {'id': id};
  },
  defaults: () => const {},
);
```

Render with `when`:

```dart
final view = result.when(
  context: context,
  idle: (data) => Text('Idle: $data'),
  pending: (_) => const CircularProgressIndicator(),
  success: (data) => Text('Loaded: $data'),
  error: (err) => Text('Error: ${err?.error}'),
);
```

Trigger refresh:

```dart
await result.refresh();
```

## Flutter Example (from the example app)

::: code-group

<<< ../../example/lib/main.dart#async-data-section [useAsyncData]

:::
