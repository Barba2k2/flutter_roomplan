# Flutter Apple Camera APIs

A monorepo of Flutter plugins that expose Apple's camera, capture, vision, and 3D scanning frameworks to Dart / Flutter on iOS (and macOS, where applicable).

The goal is to ship one focused, independently versioned plugin per Apple framework, plus an optional umbrella package that re-exports the whole family for consumers who want everything under a single import.

## Packages

| Package | Apple framework(s) | pub.dev | Status |
| --- | --- | --- | --- |
| [`roomplan_flutter`](packages/roomplan_flutter) | RoomPlan | [pub.dev](https://pub.dev/packages/roomplan_flutter) | Stable |
| `flutter_object_capture` | RealityKit Object Capture (PhotogrammetrySession) | — | Planned |
| `flutter_realitykit` | RealityKit | — | Planned |
| `flutter_apple_vision` | Vision | — | Planned |
| `flutter_visionkit` | VisionKit | — | Planned |
| `flutter_avfoundation_camera` | AVFoundation capture pipeline | — | Planned |
| `flutter_photokit` | Photos / PhotoKit / PhotosUI | — | Planned |
| `flutter_core_image` | Core Image (+ Image I/O) | — | Planned |
| `apple_camera_kit` | Umbrella package (re-exports all of the above) | — | Planned |

See [`docs/PACKAGES.md`](docs/PACKAGES.md) for the full roadmap, scope per package, and platform support matrix.

## Why a monorepo

- **Atomic changes** across packages (e.g. updating the umbrella when a child ships a breaking change) live in a single PR.
- **Shared CI, lints, and tooling** — one `analysis_options.yaml`, one CI workflow, one release pipeline.
- **Local development** — Melos wires every package together with path-based overrides, so changes in one package are immediately visible to the others without publishing.
- **Centralized issues and discussions** — contributors don't need to guess which repo to file a bug against.

The architecture and the umbrella package model are documented in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Getting started (development)

### Prerequisites

- Flutter `>=3.10.0` (Dart `>=3.0.0`)
- Xcode 15+ (for iOS plugins)
- A device with LiDAR for any plugin that requires it (RoomPlan, Object Capture)

### One-time setup

```bash
# Install Melos (once per machine)
dart pub global activate melos

# Bootstrap the workspace: resolves dependencies for every package
# and wires path-based overrides between them.
melos bootstrap
```

### Day-to-day commands

```bash
melos run analyze       # static analysis across all packages
melos run format        # auto-format
melos run format-check  # CI-friendly formatting check
melos run test          # run tests in every package that has tests
melos run pub-get       # pub get everywhere
melos run clean         # flutter clean everywhere
```

### Running a specific package's example

```bash
cd packages/roomplan_flutter/example
flutter run
```

Path-based dependencies are configured automatically by `melos bootstrap`, so editing a package's source is reflected in its example without re-installing.

## Repository layout

```
flutter_roomplan/
├── melos.yaml                    # workspace orchestration
├── pubspec.yaml                  # workspace root (Melos as dev dep)
├── analysis_options.yaml         # workspace-wide analyzer excludes
├── README.md                     # this file
├── LICENSE
├── CONTRIBUTING.md
├── docs/
│   ├── ARCHITECTURE.md           # umbrella model, package boundaries
│   └── PACKAGES.md               # full package roadmap
└── packages/
    └── roomplan_flutter/         # first plugin (existing)
        ├── pubspec.yaml
        ├── lib/
        ├── ios/
        ├── test/
        └── example/
```

New packages follow the same shape under `packages/<package_name>/`.

## Versioning and publishing

Each package is versioned **independently** and published to pub.dev under its own name. Git tags use the `<package_name>-v<version>` convention (e.g. `roomplan_flutter-v0.2.0`) so a single repo can ship many releases without ambiguity.

Releases are driven by Melos (`melos version`, `melos publish`). See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full release flow.

## Contributing

Bug reports, feature requests, and PRs are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) first.

## License

[MIT](LICENSE)
