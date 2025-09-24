## 2.1.1

Status: Released (2025-09-24)

### 🐛 BUG FIXES

#### Fix reset state to memoized store root

Previously, memoization reset depended on widget effects. If the widget itself used useMemoized , the memoized node would not be reset to the top.

This has now been fixed, and widget effects no longer rely on signals to reset memoization.

> Thx [@definev2 (Zen Bui)](https://x.com/definev2) - [1970659750242328584](https://x.com/definev2/status/1970659750242328584)

## 2.1.0

Status: Released (2025-09-23)

### 💥 BREAKING CHANGES

#### Remove `GlobalSignals.*` APIs

- `GlobalSignals.create(value)` -> `signal(null, value)`
- `GlobalSignals.computed(getter)` -> `computed(null, getter)`
- `GlobalSignals.effect(callback)` -> `effect(null, callback)`
- `GlobalSignals.effectScope(callback)` -> `effectScope(null, callback)`

#### Remove Widget Reference

The widget reference system was overly complex and unnecessary since widgets
already handle their own context and props naturally.

Direct access to widget properties is now used instead of the ref abstraction.

```diff
class MyWidget extends StatelessWidget {
  MyWidget({super.key, required this.name})

  final String name;

  @override
  Widget build(BuildContext context) {
-    final ref = useRef(context);
    effect(context, () {
-      print(ref.widget.name);
+      print(name)
    });
    //...
  }
}

class MyWidget2 extends StatefulWidget {
  final String name;

  createState() => MyState2(this);
}

class MyState2 extends State<MyWidget2> {
  @override
  Widget build(BuildContext context) {
-    final ref = useRef();
    effect(context, () {
-      print(ref.widget.name);
+      print(name)
    });
    //...
  }
}
```

### Remove `SignalBuildContext` extension

Defining external functions by extensions was always less than ideal, and now `watch` has been moved to the top level.

```diff
-final value = context.watch(count);
+final value = watch(context,count);
```

### 🔧 IMPROVEMENTS

- Improved performance: Optimized ref creation and update logic, reducing unnecessary rebuilds

## 2.0.2

Status: Released (2025-09-23)

### ✨ NEW FEATURES

#### Reactive Primitives

Now, `signal`/`computed`/`effect`/`effectScope` make reactive primitives

```diff
// After
-final count = GlobalSignals.create(0);

// Now
+final count = signal(null, 0);
```

### 🔧 IMPROVEMENTS

- Deprecate GlobalSignals in favor of direct imports
- Fixed widgets being unmounted still triggering effects.

## 2.0.1

- Fix `ReactiveList.add` implementation for non-nullable elements

## 2.0.0

### 💥 BREAKING CHANGES

This is a complete rewrite of Oref with breaking changes to most APIs. The new version provides better performance, cleaner APIs, and improved developer experience.

#### API Changes
- **`useSignal` → `signal`**: Replace `useSignal(context, value)` with `signal(context, value)`
- **`useComputed` → `computed`**: Replace `useComputed(context, computation)` with `computed(context, computation)`
- **`useEffect` → `effect`**: Replace `useEffect(context, callback)` with `effect(context, callback)`
- **`useEffectScope` → `effectScope`**: Replace `useEffectScope(context)` with `effectScope(context)`
- **Widget Effect Hooks**: `getWidgetEffect` and `getWidgetScope` renamed to `useWidgetEffect` and `useWidgetScope`
- **Memoization**: `resetMemoized` renamed to `resetMemoizedFor` for clarity
- **Reactive Access**: Direct signal calls now supported in widgets (e.g., `Text('${count()}')`), replacing the need for `SignalBuilder` in many cases

#### Removed Features
- Removed entire old signal system implementation (848 lines deleted)
- Removed global async computed APIs (`createGlobalAsyncComputed`, `useAsyncComputed`)
- Removed legacy primitive operators
- Removed old async utilities and global signal management

### ✨ NEW FEATURES

#### Reactive Collections
- **`ReactiveList<T>`**: Reactive wrapper for List operations with automatic dependency tracking
- **`ReactiveMap<K, V>`**: Reactive wrapper for Map operations with automatic dependency tracking
- **`ReactiveSet<T>`**: Reactive wrapper for Set operations with automatic dependency tracking
- **Factory Constructors**: Support for widget-scoped reactive collections via `.scoped()` constructors
- **Global Collections**: Support for global reactive collections via default constructors

#### Enhanced Widget Integration
- **`SignalBuilder`**: New widget for explicit reactive UI updates
- **`SignalBuildContext` Extension**: Adds `context.watch()` method for reactive value access
- **Direct Signal Access**: Signals can now be called directly in widget build methods
- **Improved Widget Effects**: Better automatic rebuild triggering when signal dependencies change

#### New Utilities
- **`GlobalSignals`**: Utility class for managing global signal instances
- **`batch()` and `untrack()`**: Export utility functions from alien_signals for advanced use cases
- **Enhanced Ref System**: Improved `Ref`, `StateRef`, and `WidgetRef` utilities moved to dedicated utils module

### 🔧 IMPROVEMENTS

#### Performance
- Built on alien_signals v0.5.3 for optimal performance
- Removed global mutable state in computed values
- Improved memoization with better scope handling and lifecycle management
- Simplified effect and scope management for reduced overhead

#### Developer Experience
- **Better Documentation**: Comprehensive inline documentation with examples for all APIs
- **Cleaner API Surface**: More intuitive function names following React hooks conventions
- **Simplified Widget Integration**: Signals can be used directly in widget build methods without complex setup
- **Better Error Handling**: Improved assertions and error messages for memoization and widget context usage
- **Organized Code Structure**: Reorganized exports and moved utilities to separate directories for better maintainability

#### Architecture
- **Complete Rewrite**: Built from ground up with lessons learned from v1.x
- **Widget Effect System**: New widget effect pattern for consistent scope management
- **Improved Memoization**: Better widget-scoped memoization with proper lifecycle management
- **Modular Design**: Clear separation between core primitives, reactive collections, utilities, and widgets
- **Type Safety**: Enhanced type safety throughout the API surface

### 🔄 MIGRATION GUIDE

#### Basic Signal Usage
```dart
// v1.x
final count = useSignal(context, 0);

// v2.0
final count = signal(context, 0);
```

#### Computed Values
```dart
// v1.x
final doubled = useComputed(context, () => count.value * 2);

// v2.0
final doubled = computed(context, () => count() * 2);
```

#### Effects
```dart
// v1.x
useEffect(context, () {
  print('Count: ${count.value}');
});

// v2.0
effect(context, () {
  print('Count: ${count()}');
});
```

#### Widget Reactivity
```dart
// v1.x - Required SignalBuilder or manual tracking
SignalBuilder(
  signal: count,
  builder: (context, value, _) => Text('Count: $value'),
)

// v2.0 - Direct access supported
Text('Count: ${count()}')
// or explicit watching
Text('Count: ${context.watch(() => count())}')
// or SignalBuilder
SignalBUilder(
  getter: count,
  builder: (context, value) => Text('Count: $value'),
);
```

#### Reactive Collections
```dart
// v2.0 - New feature
final items = ReactiveList<String>(['a', 'b', 'c']);
final itemsScoped = ReactiveList.scoped(context, ['a', 'b', 'c']);
```

### 🗂️ PACKAGE STRUCTURE

The new version features a well-organized package structure:
- **Core**: `signal`, `computed`, `effect`, `effectScope`, `useMemoized`, widget effects
- **Reactive**: `Reactive` mixin, `ReactiveList`, `ReactiveMap`, `ReactiveSet`
- **Utils**: `batch`, `untrack`, `GlobalSignals`, `Ref` utilities, `SignalBuildContext`
- **Widgets**: `SignalBuilder` for explicit reactive UI

### ⚡ PERFORMANCE

- Upgraded to alien_signals v0.5.3 for optimal performance
- Removed global state management overhead
- Streamlined memoization and effect tracking
- More efficient widget rebuild patterns

### 📦 DEPENDENCIES

- **alien_signals**: ^0.5.3 (upgraded from ^0.4.2)
- **Flutter SDK**: ^3.8.1 (maintained)

---

## v1.1.3

- pref: Refactor binding system to use LinkedBindingNode hierarchy

## v1.1.2

- Not returning use* hooks as expected

## v1.1.1

- fix: Nested hooks cause context binding to be reset

## v1.1.0

- refactor: refactor core code to make it easier to maintain and less redundant
- refactor: Remove `createGlobalAsyncComputed` and `useAsyncComputed`
- feat: `createGlobalSignal` supports automatic trigger of Widget
- feat: `createGlobalComputed` supports automatic trigger of Widget
- feat: Added `createGlobalAsyncResult` and `useAsyncResult` to replace `createGlobalAsyncComputed`/`useAsyncComputed`

## v1.0.0

### Added
- Initial release of Oref - A reactive state management library for Flutter
- Core reactive primitives:
  - `useSignal` - Create reactive signals with automatic dependency tracking
  - `useComputed` - Create computed values that update when dependencies change
  - `useEffect` - Create side effects that run when dependencies change
  - `useEffectScope` - Create effect scopes for managing multiple effects
  - `ref` - Convert non-reactive Widget parameters to reactive signals
- Global APIs for use outside of widgets:
  - `createGlobalSignal` - Create global signals
  - `createGlobalComputed` - Create global computed values
  - `createGlobalEffect` - Create global effects
  - `createGlobalEffectScope` - Create global effect scopes
  - `createGlobalAsyncComputed` - Create global async computed values
- Async computed values with `useAsyncComputed`
- Batching utilities with `batch` function
- `untrack` utility for reading signals without creating dependencies
- Built-in type signal operators for enhanced type safety
- Automatic Widget rebuilding integration
- Performance optimizations with alien_signals backend

### Features
- 🚀 High performance reactive system built on alien_signals
- 🪄 Magic in widgets - add reactivity to any existing Widget seamlessly
- 🔄 Automatic dependency tracking and updates
- 🎯 Full type safety with Dart's strong type system
- 🔧 Flexible integration with any Flutter widget
- 📦 Lightweight with minimal overhead

### Dependencies
- Flutter SDK ^3.8.1
- alien_signals ^0.4.2
