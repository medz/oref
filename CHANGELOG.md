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
