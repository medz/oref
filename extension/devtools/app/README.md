# Oref DevTools Extension App

This directory contains the Flutter web app that powers Oref's DevTools
extension UI.

## Requirements

- Flutter 3.47.0 or newer
- Dart 3.13.0 or newer

The minimum Flutter version matches Oref: the analyzer toolchain requires
`meta` 1.18.3+, which conflicts with the versions pinned by older Flutter SDKs.

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
