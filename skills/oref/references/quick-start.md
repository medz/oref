# Quick Start

## Install

```bash
flutter pub add oref
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  oref: any
```

## Minimal signal + computed + effect

```dart
final count = signal(context, 0);
final doubled = computed(context, (_) => count() * 2);

effect(context, () {
  debugPrint('count = ${count()}');
});

Text('Count: ${count()} / ${doubled()}');
```

## Scope rebuilds with SignalBuilder

```dart
SignalBuilder(
  builder: (context) {
    final count = signal(context, 0);
    return Text('Count: ${count()}');
  },
);
```

Next: see `core-api.md` for context rules, batch/untrack, and writable computed.
