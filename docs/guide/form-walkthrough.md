# Form Validation + Async Save

This walkthrough shows `.set(...)`, `computed`, `effect`, and `useAsyncData`
working together for a real form.

## Model & validation

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

## Async save

```dart
final submit = useAsyncData<String>(context, () async {
  await Future.delayed(const Duration(milliseconds: 600));
  return 'Saved ${name()} <${email()}>';
});
```

Track saves with an `effect`:

```dart
final lastSaved = signal(context, 'never');

effect(context, () {
  if (submit.status == AsyncStatus.success) {
    lastSaved.set('just now');
  }
});
```

## UI wiring

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

This pattern keeps validation in `computed`, writes through `.set(...)`,
triggers async work via `useAsyncData`, and updates UI with `SignalBuilder`.
