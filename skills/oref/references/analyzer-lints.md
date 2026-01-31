# Analyzer Lints

## Enable the plugin

Use the top-level `plugins` section (Dart 3.10 / Flutter 3.38+). Match the plugin version to your dependency version.

```yaml
plugins:
  oref: <version>
```

Suppress a diagnostic inline when needed:

```dart
// ignore: oref/avoid_hooks_in_control_flow
```

## Lint catalog (summary)

| Lint                                  | Summary                                                          |
| ------------------------------------- | ---------------------------------------------------------------- |
| `avoid_custom_hooks_outside_build`    | Call custom hooks only in build or another hook.                 |
| `avoid_hooks_in_control_flow`         | Call hooks unconditionally at the top level of build.            |
| `avoid_hooks_in_nested_functions`     | Do not call hooks inside nested functions in build.              |
| `use_build_context_for_hooks`         | Pass `BuildContext` to optional-context hooks inside build.      |
| `avoid_hook_context_outside_build`    | Only pass `BuildContext` to hooks in build; use `null` outside.  |
| `avoid_discarded_global_effect`       | Keep the dispose handle from global effects/scopes.              |
| `avoid_effect_cleanup_outside_effect` | Call `onEffectCleanup`/`onEffectDispose` only inside `effect()`. |
| `avoid_scope_dispose_outside_scope`   | Call `onScopeDispose` only inside `effectScope()`.               |
| `avoid_writes_in_computed`            | Do not write to signals inside computed getters.                 |

For hook ordering rules and lifecycle details, see `hooks-lifecycle.md`.
