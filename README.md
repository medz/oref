# Oref

State and asynchronous resources for Dart and Flutter, built on
[alien_signals](https://github.com/medz/alien-signals-dart).

**3.0.0-dev.1 is an unpublished development version.** This checkout documents
the new 3.0 API. The package currently published on pub.dev has a different API.
Requires Dart 3.13+ and Flutter 3.47+.

Oref keeps local values, queries, pagination, actions, and writable remote values
in ordinary Dart objects. Flutter adapters observe them, own local resources, or
borrow shared ones. Business callbacks receive data rather than a BuildContext.

## Getting started

Run `flutter pub get` in this checkout. To try 3.0 in another application,
configure a path dependency pointing at this checkout. An unqualified
`flutter pub add oref` resolves the published package, not this development API.

One package provides two complete entrypoints:

```dart
import 'package:oref/oref.dart'; // State and resources; no Flutter imports.
import 'package:oref/flutter.dart'; // Same API plus Flutter adapters.
```

Choose the entrypoint needed by each file. With Material and Oref's Action, hide
Flutter's Action or use an import prefix:

```dart
import 'package:flutter/material.dart' hide Action;
import 'package:oref/flutter.dart';
```

## Local state

StateBuilder creates an object once and observes the values read by its builder:

```dart
StateBuilder<Value<int>>(
  create: () => Value(0),
  builder: (context, count) => FilledButton(
    onPressed: () => count.value++,
    child: Text('Count: ${count.value}'),
  ),
)
```

Use Watch for existing values. Computed derives reusable synchronous values;
batch groups synchronous changes. Replace collections with new immutable values.

```dart
final first = Value('Ada');
final last = Value('Lovelace');
final fullName = Computed(() => '${first.value} ${last.value}');

batch(() {
  first.value = 'Grace';
  last.value = 'Hopper';
});
```

## Resources

| API | Purpose |
| --- | --- |
| Query<S, T> | Load and refresh one result for an input snapshot. |
| Pages<S, T, C> | First page, append, cursors, and first-page refresh. |
| Action<A, R> | Explicit operation with one active write per instance. |
| RemoteValue<S, T> | Remote reads, optimistic replacement, and failure rollback. |
| Query.field / fieldAck | A writable field view of the parent model. |
| Family<K, R> | Stable resource definitions and lazy references by key. |
| Resources | Namespace isolation and bounded idle retention. |

Construction sends no request. An owning Flutter adapter starts its read after
mounting:

```dart
QueryBuilder<String, String>.create(
  source: () => 'welcome',
  load: (key, request) async => 'Hello, $key',
  builder: (context, state, query) => Column(
    children: [
      if (state.pending) const LinearProgressIndicator(),
      if (state.hasValue) Text(state.value),
      if (state.error != null) Text('${state.error}'),
      TextButton(
        onPressed: () => query.refresh().ignore(),
        child: const Text('Refresh'),
      ),
    ],
  ),
)
```

Only synchronous reads inside source establish request dependencies. Inputs use
Dart `==`; immutable records work well. Loaders, writers, and actions run without
collecting dependencies. Widget updates install the latest callbacks without
repeating requests for equal inputs.

ensureLoaded reuses the current attempt, including its failed Future. Retry with
refresh. Pagination refresh reloads only the first page. Pending reads share one
Future; competing writes fail with ResourceReason.busy.

Explicit operations return native Futures. Await and handle errors, attach an
error handler, or call ignore when the UI deliberately renders state.error.
Ignoring a Future does not clear its error state.

## Ownership and sharing

| Flutter constructor | Lifetime |
| --- | --- |
| create / remote ack | Owns, starts reads, and disposes its resource. |
| value | Only observes; the external owner starts, configures, and disposes it. |
| shared | Borrows from ResourceScope, starts reads, and returns the borrow on unmount. |

Actions never run automatically. ResourceScope.create and value follow the same
ownership rule. Put the scope above Navigator so routes share one directory.
Set maxIdle and retain explicitly at the root; active consumers and unfinished
writes are outside the idle-entry limit.

```dart
final article = Family<int, Query<int, String>>(
  create: (id) => Query(
    source: () => id,
    load: (id, request) async => 'Article $id',
  ),
  dispose: (query) => query.dispose(),
);

// Use a stable Family definition at the application boundary.
ResourceScope.create(
  create: () => Resources(
    namespace: () => null,
    maxIdle: 32,
    retain: const Duration(minutes: 2),
  ),
  child: MaterialApp(
    home: QueryBuilder<int, String>.shared(
      ref: article(42),
      builder: (context, state, query) => Scaffold(
        body: Center(child: Text(state.hasValue ? state.value : 'Loading…')),
      ),
    ),
  ),
)
```

For account-specific resources, give every login/logout a new namespace identity.
Keep credentials in source snapshots. Accepted writes finish with their original
parameters; old results cannot publish into the new namespace.

The [complete follow example](example/lib/shared_follow.dart) includes a model,
fake server, login continuation, session identity, two routes, optimistic field
writes, rollback, and disposal. The [article example](example/lib/article_pages.dart)
shows filtering, pagination, refresh, retry, and detail navigation. See the
[run instructions and Flutter screenshot](example/README.md).

## Documentation

- [Getting started](docs/guide/getting-started.md)
- [Values and subscriptions](docs/guide/local-state.md)
- [Queries](docs/guide/query.md), [pagination](docs/guide/pages.md), [actions](docs/guide/action.md)
- [Remote values and fields](docs/guide/remote-value.md)
- [Sharing and sessions](docs/guide/sharing.md)
- [Flutter ownership](docs/guide/flutter.md), [errors and cancellation](docs/guide/errors.md)
- [简体中文](docs/zh/guide/getting-started.md)
- [Agent usage skill](skills/oref/SKILL.md)

## Moving from 2.x

3.0 replaces the old API. Import flutter.dart for widgets. Use Value/Computed for
local values, Watch or StateBuilder for observation, and Query/Pages/Action or
RemoteValue for asynchronous work. Replace mutable collection wrappers with new
immutable collections. Hooks, analyzer rules, and the DevTools extension were
removed; remove the old plugin configuration from consuming applications.

## Development

Run `flutter test` and `dart analyze` at the root, and `flutter test` in example.
Build the documentation with `bun run docs:build` from docs.

Oref is [MIT licensed](LICENSE). Development is supported by
[sponsors](https://github.com/sponsors/medz).
