# CLAUDE.md

Guidance for AI assistants (Claude Code et al.) working in this repository.

## What this is

A **Flutter monorepo** (`flutter_apple_camera_workspace`) for plugins that wrap Apple's camera, capture, vision, and 3D-scanning frameworks for Dart/Flutter on iOS (and macOS, where applicable).

- Repo identity: `Barba2k2/flutter_roomplan` on GitHub.
- One published plugin so far: [`roomplan_flutter`](packages/roomplan_flutter) (RoomPlan wrapper, Stable, on pub.dev).
- Several siblings planned (`flutter_object_capture`, `flutter_apple_vision`, `flutter_visionkit`, `flutter_avfoundation_camera`, `flutter_photokit`, `flutter_core_image`) plus an umbrella package `apple_camera_kit`.
- Roadmap and scope per package: [`docs/PACKAGES.md`](docs/PACKAGES.md). Architecture and the umbrella model: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

Background: the repo was recently converted from a single-package layout into a Melos-managed monorepo (commit `e59c0a7`, PR #2). The historical name `roomplan_flutter` is preserved for pub.dev continuity; new packages use the `flutter_<framework>` convention.

## Stack and SDK requirements

- Dart `^3.0.0`, Flutter `>=3.10.0`.
- Workspace orchestration: [Melos](https://melos.invertase.dev/) `^6.3.0` (declared in root `pubspec.yaml`).
- iOS: Xcode 15+. RoomPlan requires iOS 16+ and a device with LiDAR (no simulator support for actual scanning).
- Native code: Swift (iOS). Plugins are platform-channel based.

## Repo layout

```
flutter_roomplan/
├── melos.yaml                    # workspace orchestration + scripts
├── pubspec.yaml                  # workspace root; Melos as dev dep; publish_to: none
├── analysis_options.yaml         # workspace-wide analyzer excludes
├── README.md                     # consumer-facing overview
├── CONTRIBUTING.md               # workflow, branches, releases — read this first
├── docs/
│   ├── ARCHITECTURE.md           # umbrella model, package boundaries, CI/release plan
│   └── PACKAGES.md               # full roadmap + per-package scope, status, platforms
└── packages/
    └── roomplan_flutter/
        ├── pubspec.yaml          # v0.1.4, iOS plugin
        ├── analysis_options.yaml # include: package:flutter_lints/flutter.yaml
        ├── CHANGELOG.md
        ├── README.md             # rich consumer docs + API reference
        ├── lib/                  # Dart source
        ├── ios/                  # Swift plugin code
        ├── test/                 # Flutter tests
        └── example/              # runnable example app
```

`melos.yaml` globs both `packages/*` and `packages/*/example`, so example apps are treated as workspace members and get the same path overrides.

## `packages/roomplan_flutter` source layout

Public API lives in `lib/api/`; internal implementation lives in `lib/src/`. Always re-export new public symbols from `lib/roomplan_flutter.dart`.

```
lib/
├── roomplan_flutter.dart         # barrel; public exports
├── api/
│   ├── room_plan_scanner.dart    # main class: startScanning, stopScanning, onScanResult
│   ├── exceptions.dart           # rich exception hierarchy
│   └── models/                   # ScanResult, RoomData, RoomDimensions, WallData,
│                                 # ObjectData, OpeningData, Position, ScanConfiguration,
│                                 # ScanMetadata, ScanConfidence, Confidence, MeasurementUnit
└── src/
    ├── mapper.dart               # JSON → Dart models
    ├── services/room_plan_channel.dart  # MethodChannel bridge
    ├── models/                   # intermediate/internal models
    └── performance/              # optimized_mapper, object_pool, performance_monitor

ios/
├── SwiftFlutterRoomplanPlugin.swift  # plugin registration + channel handlers
├── RoomPlanController.swift          # ARKit/RoomPlan session lifecycle
└── RoomPlanJSONConverter.swift       # Apple RoomPlan → JSON for Dart

test/      # mapper, models, unit conversions, floor/ceiling, performance, channel mocks
example/   # full Flutter app demonstrating scanning, stats, room views
```

When adding a new public symbol: export it from `lib/roomplan_flutter.dart` and document it in `CHANGELOG.md` for the next release (CONTRIBUTING checklist).

## Development workflow

### One-time setup

```bash
dart pub global activate melos
melos bootstrap     # pub get + path-based dependency_overrides between packages
```

`melos bootstrap` is what wires intra-workspace dependencies to local paths instead of pub.dev. Run it after pulling changes that touch `pubspec.yaml` files, after adding a package, or whenever resolved dependencies look stale.

### Daily commands (from repo root)

```bash
melos run analyze        # dart analyze across all packages
melos run format         # dart format (writes changes)
melos run format-check   # dart format --set-exit-if-changed (CI variant)
melos run test           # flutter test in every package that has a test/ dir
melos run pub-get        # flutter pub get everywhere
melos run clean          # flutter clean everywhere
```

All scripts run with `melos exec -c 1` (sequential). Don't bypass them with raw `dart`/`flutter` commands at the root — those won't see workspace overrides.

### Per-package work

```bash
cd packages/roomplan_flutter
flutter analyze
flutter test
```

### Running the example app

```bash
cd packages/roomplan_flutter/example
flutter run
```

Path overrides are already wired by `melos bootstrap`; editing the plugin's `lib/` is reflected immediately.

## Conventions

### Commits — Conventional Commits, scope = package name

```
feat(roomplan_flutter): expose floor plan extraction API
fix(roomplan_flutter): correct unit conversion for inch values
chore: bump melos to 6.4.0
docs(architecture): clarify umbrella package boundaries
```

Scope is optional but recommended — it keeps per-package `git log` readable and feeds Melos's automatic changelog generation. Use a bare type (no scope) for workspace-wide chores.

### Branches

- `main` — stable; releases tagged here.
- Cross-cutting: `feat/<short-description>`, `fix/<short-description>`, `chore/<short-description>`.
- Package-scoped: `feat/<package>/<short-description>` (e.g. `feat/object_capture/initial-skeleton`).

### Code style

- Lints come from `flutter_lints` (`include: package:flutter_lints/flutter.yaml` in each package).
- Root `analysis_options.yaml` excludes `.dart_tool/`, `build/`, `**/*.g.dart`, `**/*.freezed.dart`, and example build outputs.
- Always run `melos run format` before committing. CI uses `format-check`.

### Adding a new package (from CONTRIBUTING)

1. `packages/flutter_<framework>/` with the standard plugin layout (`pubspec.yaml`, `lib/`, `ios/`, `example/`, `test/`, `README.md`, `CHANGELOG.md`, `LICENSE`).
2. `version: 0.0.1` and a clear `description` in `pubspec.yaml`.
3. `melos bootstrap` from the repo root.
4. Add a row to the table in `README.md` and document scope/status in `docs/PACKAGES.md`.

Plugins must not depend on each other (sibling rule from ARCHITECTURE.md). The umbrella `apple_camera_kit` is the only package that depends on all of them and is pure Dart.

## Versioning and releases

Each package is versioned **independently**. Tags use `<package_name>-v<version>` (e.g. `roomplan_flutter-v0.1.5`).

```bash
melos version              # bump versions + tags + per-package CHANGELOG entries
melos publish --dry-run
melos publish --no-dry-run
```

Never run `flutter pub publish` directly from a package — Melos coordinates the dependency-override rewrites that pub.dev expects. `melos.yaml` is configured with `workspaceChangelog: false`, `updateGitTagRefs: true`, `linkToCommits: true`, `branch: main`.

## CI

There are no `.github/workflows/` files yet (this monorepo conversion is recent). The plan in `docs/ARCHITECTURE.md` is: `melos bootstrap` → `melos run format-check` → `melos run analyze` → `melos run test` → iOS build verification on changed example apps. If you add CI, mirror those steps.

## Code-review checklist (from CONTRIBUTING)

- [ ] `melos run test` passes
- [ ] `melos run analyze` is clean
- [ ] `melos run format-check` passes
- [ ] Public API changes are documented in the package's `CHANGELOG.md`
- [ ] If touching iOS native code: example app builds and runs on a real device
- [ ] If adding a new public symbol: it's re-exported from the package's main library file

## Gotchas

- **No simulator scanning.** RoomPlan needs a LiDAR-equipped device (iPhone 12 Pro+, iPad Pro 5th gen+). Don't write tests that exercise the platform channel against a stub expecting real scan data.
- **Two mappers exist.** `lib/src/mapper.dart` is the readable reference; `lib/src/performance/optimized_mapper.dart` is the ~3× faster single-pass implementation used at runtime. If you change one, keep the other in sync — the `performance_test.dart` benchmark guards against regressions.
- **`simd_float3` convention.** Several historical bugs came from mismatched axis order between Swift (`simd_float3`) and Dart `Vector3`. Check both `mapper.dart` and `optimized_mapper.dart` when touching dimension logic.
- **Don't add cross-package Dart deps.** Plugins are siblings; coupling them defeats the umbrella model. Shared utilities, if ever needed, should live in a dedicated internal package — discuss in `docs/ARCHITECTURE.md` first.
- **`analysis_options.yaml` at the root excludes generated files only** — it does not include lints. Package-level options pull in `flutter_lints`. Don't rely on root-level analyzer settings for style rules.
