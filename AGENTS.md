# Repository Guidelines

## Current scope

Oref 3 is a core-only development implementation over alien_signals 2.3.5.
The old 2.x runtime, Flutter integration, hooks, collections, async utilities,
analyzer plugin, and DevTools extension are removed. Do not restore them or the
closed resource RFC without a new explicit direction. See design issue #47.

## Structure

- `lib/oref.dart`: public core entry point.
- `lib/src/core/`: object-shaped primitives and synchronous boundaries.
- `test/`: semantic and regression tests against the actual substrate.
- `example/oref_example.dart`: runnable core example.
- `docs/`: VitePress guide and retained site theme/branding.
- `skills/oref/`: installation guidance for agents using this API.

## Commands

- `dart pub get`
- `dart format --output=none --set-exit-if-changed lib test example`
- `dart analyze`
- `dart test`
- `dart run example/oref_example.dart`
- `dart pub publish --dry-run` (validation only, never publish without approval)
- `cd docs && bun install --frozen-lockfile && bun run docs:build`

## Architecture

Delegate values, computed caches, dependency tracking, ownership and propagation
to alien_signals. The public `trigger` helper is an intentional delegation to
upstream preset semantics for explicit same-identity notification. Do not add a
custom notification mechanism, second graph, scheduler, or independent owner/Zone
mechanism. Public values use `.value`; lifecycle objects use `.dispose()`.
The Effect cleanup registration adapter and reusable ReactiveScope.run boundaries
must clearly distinguish their own policies from upstream guarantees.

Use public upstream exports, not package-private imports or numeric flag literals.
Test upstream edge cases rather than promising stronger behavior accidentally.
All tracking and ownership boundaries are synchronous and do not cross await.
Keep computed callbacks free of side effects; this is usage guidance, not a new
runtime write prohibition or a claim that upstream detects arbitrary cycles.

## Changes and review

Use standard Dart formatting and snake_case file names. Keep public exports small.
Add regressions for changes to lifecycle, cleanup, exceptions, or reentrancy.
Update README, the core guide, and Unreleased changelog for public behavior.
The current 3.0.0-dev.0 work is unpublished: keep its notes under Unreleased
until an actual release is prepared, rather than implying it has shipped.
Document actual verification and any limitations in PR descriptions. Draft PRs
must not be merged, released, or deployed without explicit authorization.
