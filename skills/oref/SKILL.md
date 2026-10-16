---
name: oref
description: Use Oref 3 values, asynchronous resources, shared families, and Flutter builders when building or reviewing Oref applications. Check the resolved package version before applying this development API.
---

# Oref usage

This skill targets **3.0.0-dev.1**, an unpublished development API. Inspect the
consumer's resolved dependency and source first. For an older version, use its
matching documentation; migrate only when the task calls for that.

Use package:oref/oref.dart for Dart business code and package:oref/flutter.dart
for widgets. Both belong to one package. With Material and Oref's Action in one
file, hide Flutter's Action or prefix imports.

| Need | API |
| --- | --- |
| Local state / synchronous derivation | Value / Computed |
| Observe existing state | Watch |
| Create and observe a local object | StateBuilder |
| One remote result | Query |
| Cursor pagination | Pages |
| Explicit command | Action |
| Optimistic remote replacement | RemoteValue |
| A writable field in an existing model | Query.field / fieldAck |
| Sharing across routes | Family + Resources + ResourceScope |

Read the relevant reference:

- [Values and Flutter](references/core.md): subscriptions, immutable collections,
  StateBuilder, native controllers, and cleanup.
- [Resources](references/resources.md): source snapshots, reads, pagination,
  actions, remote values, fields, and Future errors.
- [Sharing](references/shared.md): stable definitions, bounded caching, sessions,
  ownership, and accepted-write lifetime.

Keep HTTP, JSON, authorization, and navigation visible in application code.
Do not hide resource/session protocols in an unexplained Store or helper. Use
immutable records or value objects for inputs. Include credentials in accepted
write arguments instead of reading mutable authentication state later inside an
async action. Avoid Computed for one-use formatting.

Examples should show the owner, activation, explicit Future error consumption,
and cleanup. Match the user's language and focus on the scenario's decisions.
