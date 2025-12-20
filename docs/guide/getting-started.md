# Getting Started

## Install

```bash
flutter pub add oref
```

Or add it to `pubspec.yaml`:

```yaml
dependencies:
  oref: any
```

## First Signal

```dart
final count = signal(context, 0);

Text('Count: ${count()}');

count.set(1);
```

## Computed Values

```dart
final count = signal(context, 2);
final doubled = computed(context, (_) => count() * 2);

Text('Doubled: ${doubled()}');
```

## Effects

```dart
final count = signal(context, 0);

effect(context, () {
  debugPrint('count = ${count()}');
});
```

## Scope Rebuilds with SignalBuilder

Use `SignalBuilder` when you want only a subtree to re-render.

```dart
SignalBuilder(
  builder: (context) {
    final count = signal(context, 0);
    return Text('Count: ${count()}');
  },
);
```

Next up: **Core Concepts**.
