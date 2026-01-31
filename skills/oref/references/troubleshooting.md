# Troubleshooting

## DevTools extension not showing

- Ensure the app is running in debug mode.
- Confirm DevTools is connected to the running app.
- Enable the Oref extension in DevTools -> Extensions.
- Create at least one signal/computed/effect after startup.

## Widget not rebuilding

- Ensure the signal is read inside `build` or a `SignalBuilder` builder.
- Avoid `untrack()` when you expect rebuilds.
- Verify you are calling `.set(...)` to update the signal.
- If many writes happen, wrap them in `batch()`.

## Lint errors about hooks

- Call hooks unconditionally at the top level of a build scope.
- Do not call hooks inside nested functions or control flow.
- Pass `context` to optional-context hooks inside build; use `null` outside.

## Resource leaks

- Keep the dispose function from global `effect()` or `effectScope()`.
- Use `onEffectDispose` inside `effect()` for cleanup.

## Computed writes

- Do not write to signals inside computed getters.
- Move writes into `effect()` or event handlers.
