# Oref DevTools Extension App

This directory contains the Flutter web app that powers Oref's DevTools
extension UI.

## Requirements

- Flutter 3.38.4 or newer
- Dart 3.10.4 or newer

The minimum Flutter version is pinned here because the current
`devtools_extensions` stack resolves to dependencies that require Flutter
3.38.4+.

## Common Commands

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Rebuild the packaged DevTools extension assets:

```bash
dart run devtools_extensions validate --package=../../..
dart run devtools_extensions build_and_copy --source=. --dest=../
```
