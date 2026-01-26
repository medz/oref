[![Oref testing](https://github.com/medz/oref/actions/workflows/test.yml/badge.svg)](https://github.com/medz/oref/actions/workflows/test.yml)
[![Oref version](https://img.shields.io/pub/v/oref)](https://pub.dev/packages/oref)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/medz/oref)

# Oref

A high-performance Flutter state management tool built with [`alien_signals`](https://github.com/medz/alien-signals-dart), Oref is one of the fastest Flutter signals and state management solutions.

## Overview

Much of the pain in state management in Dart & Flutter comes from reacting to changes in given values, because the values themselves are not directly observable. We have to use `StatefulWidget` or other state management tools for state, which use inefficient proactive notifications or a large number of watchers to notify widgets to rebuild, and the boilerplate code is very redundant.

The release of `alien_signals` completely changed Flutter's inefficient state management situation, but Flutter state libraries still require a lot of boilerplate code! Oref completely changes this situation. In Flutter, when a Widget accesses a signal value, if that signal's value changes, the Widget is automatically rebuilt.

```dart
class Counter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);
    void increment() => count.set(count() + 1);

    return Column(children: [
      Text('Count: ${count()}'),
      TextButton(
        onPressed: increment,
        child: Text('click me'),
      )
    ]);
  }
}
```

Signals are magically injected into the BuildContext to provide optimal performance and ergonomic design. In the example above, we access `count()` to get the current value of the signal and complete the responsive binding with the current `Counter`. When the count value is updated, it automatically notifies the Counter to rebuild.

## Installation

You can install by editing your `pubspec.yaml` file:

```yaml
dependencies:
  oref: ^2.8.0
```

Or install by running this command:

```bash
flutter pub add oref
```

## DevTools Extension

Oref ships with a DevTools extension to inspect signals, effects, computed values,
collections, and performance snapshots.

1. Run your app in **debug** mode and open Flutter DevTools.

2. In DevTools → Extensions, enable **Oref**.
   If you want it enabled by default, add a `devtools_options.yaml` next to your
   app’s `pubspec.yaml`:

```yaml
extensions:
  - oref: true
```

Notes:

- The service extensions register automatically once a signal/computed/effect is
  created in debug mode.
- The extension relies on DevTools’ VM Service connection, so it only works when
  DevTools is connected to a running app.
- Web debug is supported; release builds are intentionally disabled.

## Documentation

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/medz/oref)

You can view details through the [API Reference in pub.dev](https://pub.dev/documentation/oref/latest/oref/) or source code comments.

## Analyzer Lints

Oref provides a custom analyzer plugin with lints for hooks, effects, and
signal usage. The new analyzer plugin system (Dart 3.10 / Flutter 3.38+) uses a
top-level `plugins` section.

Enable the plugin in your `analysis_options.yaml`:

```yaml
plugins:
  oref: ^2.8.0
```

Suppress a diagnostic in code (optional):

```dart
// ignore: oref/avoid_hooks_in_control_flow
```

### All lints

#### avoid_custom_hooks_outside_build

Custom hooks must be called inside a build scope or another hook.

**Bad**:

```dart
void useLocalCounter(BuildContext context) {
  signal(context, 0);
}

void helper(BuildContext context) {
  useLocalCounter(context);
}
```

**Good**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    useLocalCounter(context);
    return Widget();
  }
}
```

#### avoid_hooks_in_control_flow

Hooks must be called unconditionally at the top level of a build scope.

**Bad**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (true) {
      signal(context, 0);
    }
    return Widget();
  }
}
```

**Good**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = signal(context, 0);
    if (true) {
      counter.set(1);
    }
    return Widget();
  }
}
```

#### avoid_hooks_in_nested_functions

Hooks must not be called inside nested functions within a build scope.

**Bad**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void inner() {
      signal(context, 0);
    }
    inner();
    return Widget();
  }
}
```

**Good**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    signal(context, 0);
    return Widget();
  }
}
```

#### use_build_context_for_hooks

Optional-context hooks must receive `BuildContext` when called inside build
scopes.

**Bad**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    signal(null, 0);
    return Widget();
  }
}
```

**Good**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    signal(context, 0);
    return Widget();
  }
}
```

#### avoid_hook_context_outside_build

Passing `BuildContext` to hooks is only allowed in build scopes.

**Bad (optional-context hook outside build)**:

```dart
void helper(BuildContext context) {
  signal(context, 0);
}
```

**Good (optional-context hook outside build)**:

```dart
void helper() {
  signal(null, 0);
}
```

**Bad (required-context hook outside build)**:

```dart
void helper(BuildContext context) {
  watch(context, () => 1);
}
```

**Good (required-context hook inside build)**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    watch(context, () => 1);
    return Widget();
  }
}
```

#### avoid_discarded_global_effect

Discarding the result of a global effect/scope can leak resources.

**Bad**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    effect(null, () {});
    return Widget();
  }
}
```

**Good**:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dispose = effect(null, () {});
    return Widget();
  }
}
```

#### avoid_effect_cleanup_outside_effect

`onEffectCleanup`/`onEffectDispose` must be called inside `effect()`.

**Bad**:

```dart
void helper() {
  onEffectCleanup(() {});
}
```

**Good**:

```dart
void helper(BuildContext context) {
  effect(context, () {
    onEffectCleanup(() {});
  });
}
```

#### avoid_scope_dispose_outside_scope

`onScopeDispose` must be called inside `effectScope()`.

**Bad**:

```dart
void helper() {
  onScopeDispose(() {});
}
```

**Good**:

```dart
void helper(BuildContext context) {
  effectScope(context, () {
    onScopeDispose(() {});
  });
}
```

#### avoid_writes_in_computed

Avoid writing to signals inside computed getters.

**Bad**:

```dart
void helper(BuildContext context) {
  final counter = signal(context, 0);
  computed(context, () {
    counter.set(1);
    return counter();
  });
}
```

**Good**:

```dart
void helper(BuildContext context) {
  final counter = signal(context, 0);
  effect(context, () {
    counter.set(1);
  });
}
```

## Sponsors

Oref is an [MIT licensed](https://github.com/medz/spry/blob/main/LICENSE) open source project with its ongoing development made possible entirely by the support of these awesome backers. If you'd like to join them, please consider [sponsoring Seven(@medz)](https://github.com/sponsors/medz) development.

<p align="center">
  <a target="_blank" href="https://github.com/sponsors/medz">
    <img alt="sponsors" src="https://cdn.jsdelivr.net/gh/medz/public/sponsors.tiers.svg">
  </a>
</p>

## Contributing

Thank you to all the people who already contributed to Oref!

[![Contributors](https://contrib.rocks/image?repo=medz/oref)](https://github.com/medz/oref/graphs/contributors)
