# Repository guidelines

## Product and structure

This checkout implements Oref **3.0.0-dev.1**, an unpublished development API.
Keep one package and two complete entrypoints:

- lib/oref.dart: pure Dart values, resources, and sharing; no Flutter imports.
- lib/flutter.dart: the same API plus Flutter adapters.

Do not claim a pub.dev release or speed superiority without evidence. Public
examples and issue text must use generic data and omit private application code,
identifiers, credentials, and personal filesystem locations.

```text
lib/src/core/       Thin alien_signals adapter
lib/src/resources/ Query, Pages, Action, RemoteValue, cancellation
lib/src/shared/    Family references and bounded resource directory
lib/src/flutter/   Observation, builders, scope, widget ownership
test/             Tests grouped by these layers
example/           Complete shared follow and article pagination demos
skills/oref/       Usage guidance for package consumers
docs/             English and Chinese VitePress guides
docs/design/      Design notes excluded from the public site
```

Dependencies point core → resources → shared → flutter. Resource files form one
library with resource.dart and parts; shared files use shared.dart and parts.
Package-internal configuration/lifecycle functions stay out of public exports.
Reuse alien_signals for tracking, propagation, computed caching, and batching;
do not add another dependency graph or global Element scan.

Prefer KISS, ordinary immutable data, native Future, and minimal abstractions.
Use two-space indentation, snake_case.dart files, UpperCamelCase types, and
lowerCamelCase members. Format changed Dart files.

## Resource invariants

- Construction is lazy. Only source tracks synchronous reads. Loaders, writers,
  actions, and lifecycle callbacks run untracked.
- Source inputs use ==; values follow the kernel's identity comparison. Replace
  collections rather than mutating them in place.
- Active reads coalesce. Failed attempts stay cached until explicit refresh.
  Pages refresh replaces the list with the first page.
- One instance accepts one write. Query fields share its model, source, GET,
  parent write lock, and cache entry.
- Preserve business errors and stacks. ResourceException represents control
  conditions produced by this resource. An accepted writer's returned errors,
  including ResourceException from delegated resources, remain business failures.
  User update/apply callback failures are recorded only for the original source;
  control checks do not overwrite business errors. Callers consume explicit
  Future errors; automatic reads ignore them while retaining state.error.
- Dispose stops new work and publication. Accepted writes still settle their
  original Futures. Shared entries remain alive through unfinished writes.
- Namespace identity separates sessions. Capture transport credentials in inputs.
  Check ownership at operation acceptance and result publication.
- Resources requires explicit nonnegative maxIdle and retain. Idle entries pause
  source observation; expiration uses one directory timer.

## Flutter invariants

Watch and StateBuilder.builder observe synchronous Readable reads. Execute
builders only when Flutter builds the widget. Lifecycle callbacks stay untracked;
StateBuilder captures its disposer when creating the object.

create/remote ack own resources, value only observes, shared borrows/returns.
ResourceScope follows the same ownership rule. Start owned/shared reads in a
microtask outside build tracking. Actions never run automatically. Update source
and execution callbacks with widget configuration; do not replay initial seeds.
Detach observations before disposal/return. Namespace transitions also rebind
shared builders whose references compare equal.

Show cleanup for native controllers, timers, subscriptions, and owned resources.
Value and Computed need no invented disposer. Hide Flutter's Action or prefix
imports when using it alongside Oref's Action.

## Verification and docs

Requires Dart 3.13+ and Flutter 3.47+.

```sh
flutter pub get
dart format lib test example/lib example/test
dart analyze
flutter test
```

Also run flutter test in example after demo changes and bun run docs:build in
docs after documentation changes. Add regression tests for real behavior and
lifecycle races. Include a real Flutter screenshot for example UI changes;
current captures live in example/screenshots.

Update README, this file, English/Chinese guides, and the consumer skill for
public API changes. Keep substantial skill detail under skills/oref/references.
Keep design drafts out of generated public pages.

Use Conventional Commits. PRs explain concrete behavior, relevant issues,
validation, and remaining limitations. Publishing, tagging, or creating a release
requires the user's release request.
