---
name: oref
description: >-
  Use the core-only Oref 3 development API: Readable, Signal, Computed, Effect,
  ReactiveScope, batch, and untracked. Do not suggest removed 2.x hooks, collections,
  async resources, Flutter builders, analyzer plugins, or DevTools.
---

# Oref core

This checkout contains an unpublished core-only development API. Read the
[core reference](references/core-api.md) before suggesting code.

- Import `package:oref/oref.dart`.
- Use `.value` to read Signal/Computed and to write Signal.
- Effects run synchronously once at creation; register cleanup synchronously.
- Use `ReactiveScope().run(...)` to group effects, then dispose the scope.
- Tracking and ownership do not cross await. untracked exits both.
- Delegate to alien_signals semantics; do not invent custom notify, scheduler,
  owner, Zone-isolation, rollback, or resource protocols.
- Explain error and cleanup limitations honestly. Keep computed getters pure.
- Flutter adapters are not implemented. Do not reuse legacy Oref examples.
