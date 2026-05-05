# Contributing

Thanks for your interest in contributing! This repository is a Flutter monorepo orchestrated by [Melos](https://melos.invertase.dev/).

## Local setup

```bash
# Install Melos (once per machine)
dart pub global activate melos

# Clone and bootstrap
git clone https://github.com/Barba2k2/flutter_roomplan.git
cd flutter_roomplan
melos bootstrap
```

`melos bootstrap` does two things:

1. Runs `flutter pub get` in every package.
2. Wires up `dependency_overrides` so that intra-workspace dependencies resolve to the local paths instead of pub.dev.

## Workflow

### Branches

- `main` — stable. Releases are tagged from here.
- Feature branches — `feat/<short-description>`, `fix/<short-description>`, `chore/<short-description>`.
- Per-package branches when work is scoped to a single plugin: `feat/<package>/<short-description>`.

### Commits

Conventional Commits are recommended:

```
feat(roomplan_flutter): expose floor plan extraction API
fix(roomplan_flutter): correct unit conversion for inch values
chore: bump melos to 6.4.0
docs(architecture): clarify umbrella package boundaries
```

The optional scope is the package name. This keeps `git log` per-package readable and feeds Melos's automatic changelog generation.

### Working on a package

```bash
cd packages/<package_name>
# edit, then:
flutter test
flutter analyze
```

Or from the workspace root, across all packages:

```bash
melos run analyze
melos run test
melos run format
```

### Working on the example app

```bash
cd packages/<package_name>/example
flutter run
```

## Adding a new package

1. Create the directory: `packages/<new_package>/`.
2. Add the standard Flutter plugin layout: `pubspec.yaml`, `lib/`, `ios/`, `example/`, `test/`, `README.md`, `CHANGELOG.md`, `LICENSE`.
3. Set `version: 0.0.1` and a clear `description` in the package's `pubspec.yaml`.
4. Run `melos bootstrap` from the repo root so Melos picks up the new package.
5. Document the package in [`docs/PACKAGES.md`](docs/PACKAGES.md) and add a row to the table in [`README.md`](README.md).

Naming convention: `flutter_<framework>` for new packages (e.g. `flutter_object_capture`). The legacy `roomplan_flutter` is preserved because it is already published on pub.dev.

## Releasing

Each package is versioned independently. Tags follow the pattern `<package_name>-v<version>` (e.g. `roomplan_flutter-v0.1.5`).

```bash
# Stage release commits and bump versions based on conventional commits
melos version

# Publish to pub.dev (dry run first!)
melos publish --dry-run
melos publish --no-dry-run
```

Never publish manually with `flutter pub publish` from inside a package directory unless you know exactly what you're doing — Melos coordinates the dependency rewrites that pub.dev expects.

## Code review checklist

- [ ] Tests pass: `melos run test`
- [ ] Analyzer is clean: `melos run analyze`
- [ ] Code is formatted: `melos run format-check`
- [ ] Public API changes are documented in the package's `CHANGELOG.md`
- [ ] If touching iOS native code: example app builds and runs on a real device
- [ ] If adding a new public symbol: it is exported from the package's main library file

## Reporting issues

Open an issue on GitHub with:

- The affected package name (use the `pkg:<name>` label).
- Plugin version, Flutter version, Xcode version, iOS version, device model.
- Minimum reproducible code sample.
- Stack trace or relevant logs.
