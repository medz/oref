# Oref

A reactive state management library for Flutter that adds magic to any Widget with signals, computed values, and effects powered by [alien_signals](https://github.com/medz/alien_signals).

[![Oref testing](https://github.com/medz/oref/actions/workflows/test.yml/badge.svg)](https://github.com/medz/oref/actions/workflows/test.yml)
[![Oref version](https://img.shields.io/pub/v/oref)](https://pub.dev/packages/oref)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- 🚀 **High Performance**: Built on alien_signals for optimal reactivity
- 🪄 **Magic in Widgets**: Add reactivity to any existing Widget seamlessly
- 🔄 **Reactive Programming**: Automatic dependency tracking and updates
- 🎯 **Type Safe**: Full type safety with Dart's strong type system
- 🔧 **Flexible**: Works with any Flutter widget
- 📦 **Lightweight**: Minimal overhead and bundle size

## Installation

Add `oref` to your `pubspec.yaml`:

```yaml
dependencies:
  oref: latest
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

class Counter extends StatelessWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(context, 0);
    void increment() => count(count + 1);


    return Scaffold(
      appBar: AppBar(title: const Text("Counter")),
      body: Center(
        child: Text('Count: ${count()}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Core Concepts

### Signals
Reactive values that can be read and written. When a signal changes, dependent computations and effects automatically update.

```dart
final count = useSignal(context, 0);
final currentValue = count();  // Read
count(newValue);              // Write
```

### Computed Values
Derived values that automatically update when their dependencies change.

```dart
final firstName = useSignal(context, 'John');
final lastName = useSignal(context, 'Doe');
final fullName = useComputed(context, (_) => '${firstName()} ${lastName()}');
```

### Effects
Side effects that run when their dependencies change.

```dart
useEffect(context, () {
  debugPrint('Count is now: ${count()}');
});
```

### Refs
Convert non-reactive Widget constructor parameters into reactive signals.

```dart
class MyWidget extends StatelessWidget {
  final String title;

  const MyWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final titleRef = ref(context, title);

    useEffect(context, () {
      debugPrint('Title changed to: ${titleRef()}');
    });

    return Text(titleRef());
  }
}
```

### Effect Scopes
Manage a group of effects together. Effects created within the scope callback can all be stopped at once.

```dart
final stopScope = useEffectScope(context, () {
  useEffect(context, () => debugPrint('Effect 1'));
  useEffect(context, () => debugPrint('Effect 2'));
});

// Stop all effects in this scope
stopScope();
```

## API Reference

### Widget-based APIs
- `useSignal<T>(BuildContext context, T initialValue)` - Create a reactive signal
- `useComputed<T>(BuildContext context, T Function(T?) getter)` - Create a computed value
- `useEffect(BuildContext context, VoidCallback callback)` - Create a side effect
- `useEffectScope(BuildContext context, VoidCallback callback)` - Create an effect scope
- `ref<T>(BuildContext context, T value)` - Convert values to reactive signals

### Global APIs
- `createGlobalSignal<T>(T initialValue)` - Create a global signal
- `createGlobalComputed<T>(T Function(T?) getter)` - Create a global computed value
- `createGlobalEffect(VoidCallback callback)` - Create a global effect
- `createGlobalEffectScope()` - Create a global effect scope

### Utilities
- `batch<T>(T Function() callback)` - Batch multiple updates
- `untrack<T>(T Function() callback)` - Run callback without tracking dependencies

## Advanced Usage

### Batching Updates
```dart
batch(() {
  signal1(newValue1);
  signal2(newValue2);
  // All dependent computations update only once
});
```

### Async Computed Values
```dart
final userId = useSignal(context, 1);
final userProfile = useAsyncComputed(
  context,
  () => userId(),
  (userId) async {
    final response = await http.get('/api/users/${userId}');
    return UserProfile.fromJson(response.body);
});
```

## Performance Tips

1. Use `untrack` when reading signals without creating dependencies
2. Batch related updates to minimize re-renders
3. Use refs to make Widget parameters reactive
4. Create global signals for app-wide state

## License

MIT License - see the [LICENSE](LICENSE) file for details.
