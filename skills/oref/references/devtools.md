# DevTools Extension

## Setup

1. Run the app in debug mode and open Flutter DevTools.
2. In DevTools -> Extensions, enable **Oref**.
3. Optional: auto-enable with `devtools_options.yaml` next to `pubspec.yaml`:

```yaml
extensions:
  - oref: true
```

## Runtime notes

- Service extensions register after a signal/computed/effect is created in debug mode.
- The extension requires an active VM Service connection.
- Web debug is supported; release builds are intentionally disabled.

## What you can inspect

- Signals and computed values
- Effects and scopes
- Reactive collections
- Performance snapshots
