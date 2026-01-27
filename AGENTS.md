# Repository Guidelines

## Project Structure & Module Organization

- `lib/` holds the public package API, with `lib/oref.dart` re-exporting internals.
- `lib/src/` contains implementation organized by area (`core/`, `async/`, `collections/`).
- `test/` mirrors feature areas with focused unit tests (for example `test/core/signal_test.dart`).
- `example/` is a Flutter app for manual validation and demos.
- Root config files include `pubspec.yaml`, `analysis_options.yaml`, and `CHANGELOG.md`.

## Build, Test, and Development Commands

- `flutter pub get` installs dependencies for the package and the workspace example.
- `dart analyze` runs static analysis using the repo’s `flutter_lints` rules.
- `dart format .` applies standard Dart formatting across the repo.
- `flutter test` runs the full unit test suite in `test/`.
- `cd example && flutter run` launches the sample app locally for interactive checks.

## Release Process

- Update versions in `pubspec.yaml`, `extension/devtools/app/pubspec.yaml`, `extension/devtools/config.yaml`, and any version references in `README.md`.
- Move Unreleased notes into a new version section in `CHANGELOG.md`.
- Rebuild DevTools extension (from `extension/devtools/app`):
  - `flutter pub get`
  - `dart run devtools_extensions validate --package=../../..`
  - `dart run devtools_extensions build_and_copy --source=. --dest=../`
- Run tests:
  - `flutter test`
  - `cd analysis_tests && dart test`
- Commit and tag:
  - `git commit -m "Release x.y.z"`
  - `git tag vx.y.z`
- Publish to pub (from repo root):
  - `dart pub publish --dry-run`
  - `dart pub publish --force`
- Create GitHub release:
  - `git push origin vx.y.z`
  - `gh release create vx.y.z --title "vX.Y.Z" --notes-file RELEASE_NOTES.md`

## Coding Style & Naming Conventions

- Use 2-space indentation; rely on `dart format` to enforce style.
- File names are `snake_case.dart`; types are `UpperCamelCase`; methods and variables are `lowerCamelCase`.
- Keep public API surface in `lib/` and internal helpers in `lib/src/`, re-exported through `lib/oref.dart`.

## Testing Guidelines

- Tests use Flutter’s test framework via `flutter_test`.
- Name test files with the `_test.dart` suffix and colocate by feature area.
- Add regression tests for bug fixes; ensure `flutter test` passes before opening a PR.

## Commit & Pull Request Guidelines

- Commit messages follow short, imperative phrasing (examples: “Fix missing tracking…”, “Update effect…”).
- PRs should describe what changed and why, link relevant issues, and note testing performed.
- Update `CHANGELOG.md` for user-facing changes or API behavior updates.
- Include screenshots or GIFs when modifying the `example/` UI.
