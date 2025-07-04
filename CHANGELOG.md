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
