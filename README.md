[![Oref testing](https://github.com/medz/oref/actions/workflows/test.yml/badge.svg)](https://github.com/medz/oref/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

# Oref

Object-shaped reactive primitives for Dart and Flutter, built on
[alien_signals](https://github.com/medz/alien-signals-dart).

This is the core-only Oref 3 development API, not a published stable release.
It replaces the old 2.x implementation rather than providing a compatibility
layer. Flutter integration and upper-level state APIs are not implemented yet.
See [design issue #47](https://github.com/medz/oref/issues/47).

## Core API

```dart
import 'package:oref/oref.dart';

final count = Signal(0);
final doubled = Computed(() => count.value * 2);
Readable<int> value = doubled;

final scope = ReactiveScope();
scope.run(() {
  Effect((onCleanup) {
    print(value.value);
    onCleanup(() => print('Clean up this run'));
  });
});

batch(() {
  count.value = 1;
  count.value = 2;
});

print(untracked(() => doubled.value));
scope.dispose();
```

- `Readable<T>` exposes a tracked `.value` getter.
- `Signal<T>` adds a `.value` setter; comparison follows upstream `identical`.
- `Computed<T>` is lazy and cached. `Computed.withPrevious` exposes the last
  successful value when needed.
- `Effect` runs synchronously on creation, then on dependency changes.
  `onCleanup` registrations run in reverse order before reruns and disposal.
- `ReactiveScope.run` groups synchronously created effects and nested scopes.
  The scope itself does not reactively rerun.
- `batch` and `untracked` are synchronous boundaries, not async transactions.
- `trigger(() { value.value; })` explicitly notifies observers after an in-place
  mutation, using upstream semantics.

`Signal` and `Computed` directly subclass upstream preset nodes behind factory
interfaces. Lifecycle factories remain upstream-owned to preserve nested
cleanup and disposal; this is not a complete removal of upstream surface APIs.

Tracking, caching, propagation, and the effect queue remain in `alien_signals`.
There is no custom notification API, second graph, independent owner context,
or Zone-based error policy. Read the [core guide](docs/guide/reactive-core.md)
for cleanup errors, setup failure, nesting, and `await` boundaries.

## Development

Requires Dart 3.13+. To work with this unpublished version, use this checkout as
a local path dependency or run its example directly:

```sh
dart pub get
dart analyze
dart test
dart run example/oref_example.dart
```

The old hooks, collection wrappers, async utilities, Flutter adapters, analyzer
plugin, and DevTools extension have been removed. No replacement resource APIs
or widget builders are included in this core implementation.

## License

MIT. See [LICENSE](LICENSE).
