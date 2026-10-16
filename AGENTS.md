# Repository Guidelines

## Project Structure

```txt
lib/
├── src/             # Source code for the package
│   ├── async/       # Asynchronous utilities
│   ├── collections/ # Reactive collections
│   └── core/        # Oref core, widget integration, and lifecycle hooks
└── oref.dart        # Public APIs
example/             # Flutter app for manual validation and demos
skills/              # Agent Skills for Oref users (SKILL.md + references)
test/                # Mirrors feature areas with focused unit tests
```

## Build, Test, and Development Commands

- `flutter pub get` installs package dependencies; run `cd example && flutter pub get` for the example.
- `dart analyze` runs static analysis using the repo’s `flutter_lints` rules.
- `dart format .` applies standard Dart formatting across the repo.
- `flutter test` runs the full unit test suite in `test/`.
- `cd example && flutter run` launches the sample app locally for interactive checks.

## Release Process

- Update the version in `pubspec.yaml` and any version references in `README.md`.
- Move Unreleased notes into a new version section in `CHANGELOG.md`.
- Run tests:
  - `flutter test`
  - `cd example && flutter test`
- Commit and tag:
  - `git commit -m "Release x.y.z"`
  - `git tag vx.y.z`
- Publish to pub (from repo root):
  - `dart pub publish --dry-run`
  - `dart pub publish --force`
- Create GitHub release:
  - `git push origin vx.y.z`
  - `gh release create vx.y.z --title "vX.Y.Z" --notes-file RELEASE_NOTES.md`

## Package Boundaries

- Keep this package focused on reactive primitives, widget integration, lifecycle,
  async data, and collections. Analyzer plugins and inspection panels are not bundled.
- Preserve widget memoization, hot-reload callback replacement, and element/effect
  cleanup when changing core code. Debug assertions may implement core behavior;
  they are not automatically removable instrumentation.

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

## Agent Skills

- `skills/` contains Agent Skills meant for Oref users to install and use.
- Keep skills focused on Oref usage guidance; store long-form material in `references/`.

## Maintaining Documentation

When making changes to the project (new APIs, architectural changes, updated conventions):

- **`AGENTS.md`** — Update with technical details, architecture, and best practices for AI agents
- **`README.md`** — Update with user-facing documentation (usage, installation, examples) for end users
