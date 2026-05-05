# Architecture

This document describes the structural decisions behind this monorepo: how packages are organized, how they relate to each other, and how the umbrella package fits in.

## Goals

1. **One Apple framework per package.** Each Flutter plugin wraps a single, cohesive Apple framework so consumers can pull in only what they need.
2. **Independent versioning.** Each package follows its own SemVer cadence. RoomPlan and Object Capture evolve at very different paces; lockstep versioning would punish both.
3. **Optional umbrella.** A meta-package (`apple_camera_kit`) re-exports the entire family for consumers who want everything under a single import.
4. **Single source of truth for tooling.** Lints, CI, and release scripts are defined once at the workspace root.

## Package boundaries

A package belongs in this repo if it satisfies all of the following:

- It wraps an Apple-platform-specific API (iOS or macOS).
- It is a thin, idiomatic Dart layer — not an opinionated higher-level abstraction.
- It can be used standalone, without requiring sibling packages.

Packages that combine multiple frameworks into a workflow (for example, "scan a room with RoomPlan, then capture each piece of furniture with Object Capture") belong in **example apps** or **separate consumer projects**, not in this repo.

## The umbrella package (`apple_camera_kit`)

`apple_camera_kit` is a pure-Dart package with **no native code of its own**. Its `pubspec.yaml` lists every sibling plugin as a regular dependency, and its main library file simply re-exports them:

```dart
// packages/apple_camera_kit/lib/apple_camera_kit.dart
export 'package:roomplan_flutter/roomplan_flutter.dart';
export 'package:flutter_object_capture/flutter_object_capture.dart';
export 'package:flutter_apple_vision/flutter_apple_vision.dart';
// ...
```

Consumers can choose either path:

```yaml
# Option A: only what I need
dependencies:
  roomplan_flutter: ^0.2.0

# Option B: the whole family in one import
dependencies:
  apple_camera_kit: ^1.0.0
```

### Trade-off to be honest about

Installing `apple_camera_kit` pulls in **every** child plugin's native code (CocoaPods dependencies, Swift sources, frameworks). The resulting iOS binary is larger than if the consumer had picked individual packages. This is documented in the umbrella's README; the umbrella is for **convenience**, not optimization.

### Versioning the umbrella

Each release of `apple_camera_kit` pins a tested combination of child versions. Bumping a child does not automatically bump the umbrella — the umbrella is only re-released when:

- A child ships a breaking change that requires re-export updates.
- A new child is added to the family.
- The umbrella's own metadata changes (description, README, etc.).

This means the umbrella's version number reflects **compatibility releases**, not the cumulative changes of its children.

## Repository layout

```
flutter_roomplan/                 # repo root
├── melos.yaml                    # workspace orchestration
├── pubspec.yaml                  # workspace root pubspec (Melos)
├── analysis_options.yaml         # shared analyzer config
├── README.md
├── CONTRIBUTING.md
├── LICENSE
├── docs/
│   ├── ARCHITECTURE.md           # this file
│   └── PACKAGES.md               # roadmap and per-package scope
└── packages/
    ├── roomplan_flutter/         # plugin (iOS native)
    │   ├── pubspec.yaml
    │   ├── lib/
    │   ├── ios/
    │   ├── test/
    │   ├── example/              # plugin's own example app
    │   ├── README.md             # consumer-facing
    │   ├── CHANGELOG.md
    │   └── LICENSE
    ├── flutter_object_capture/   # (planned)
    ├── flutter_apple_vision/     # (planned)
    ├── ...
    └── apple_camera_kit/         # (planned) umbrella, pure Dart
        ├── pubspec.yaml
        └── lib/
            └── apple_camera_kit.dart
```

## Naming conventions

| Concern | Convention | Example |
| --- | --- | --- |
| New plugin packages | `flutter_<framework>` | `flutter_object_capture` |
| Legacy / pre-existing | preserved as-is | `roomplan_flutter` |
| Umbrella package | `apple_camera_kit` | — |
| Git tags | `<package_name>-v<version>` | `roomplan_flutter-v0.1.5` |
| Branches | `feat\|fix\|chore/<package>/<slug>` | `feat/object_capture/initial-skeleton` |
| Issue labels | `pkg:<short_name>` | `pkg:roomplan` |

## Dependency rules

Inside this monorepo:

- **Plugin packages MUST NOT depend on each other.** They are siblings; cross-dependencies create coupling that defeats the "one framework per package" goal. If two plugins genuinely need to share types, that shared code goes into a separate `*_platform_interface` or `*_core` package — but only when there is a concrete need, not preemptively.
- **The umbrella depends on every plugin.** That is its entire purpose.
- **Examples depend on their own package via `path:`.** Melos rewrites these for local development automatically.

## CI and release pipeline (overview)

CI runs from the workspace root. For every PR:

1. `melos bootstrap`
2. `melos run format-check`
3. `melos run analyze`
4. `melos run test`
5. iOS build verification on the example apps that changed.

Release pipeline (manual trigger):

1. `melos version` — bumps versions based on conventional commits, updates per-package `CHANGELOG.md`, and creates per-package git tags.
2. `melos publish --dry-run`
3. `melos publish --no-dry-run`

See [`CONTRIBUTING.md`](../CONTRIBUTING.md) for the full developer workflow.
