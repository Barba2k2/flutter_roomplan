# flutter_object_capture

[![pub package](https://img.shields.io/badge/pub-pending-lightgrey.svg)](https://pub.dev/)
[![status](https://img.shields.io/badge/status-scaffolding-orange.svg)](#status)

Flutter plugin for Apple's [RealityKit Object Capture](https://developer.apple.com/documentation/realitykit/photogrammetrysession) — guided photo capture and on-device photogrammetry that turns a set of images into a textured USDZ 3D model on iOS.

> **Status:** Early scaffolding (`v0.0.1`). The Dart public API surface is defined; the iOS native implementation is pending. **Do not use in production yet.**

## Why this package

Apple's Object Capture has two pieces:

1. **`ObjectCaptureSession`** (iOS 17+) — a guided UI that walks the user around an object while taking optimally-spaced photos.
2. **`PhotogrammetrySession`** (iOS 17+ on-device, also macOS 12+ desktop) — reconstructs a textured 3D mesh from those photos.

This plugin wraps both, exposing a clean Dart API for Flutter apps. It pairs naturally with [`roomplan_flutter`](../roomplan_flutter) — RoomPlan returns furniture as bounding boxes; Object Capture lets you replace those boxes with photorealistic meshes.

## Requirements

- iOS 17.0+
- A device with the A14 Bionic chip or newer (iPhone 12 Pro / iPad Pro 2020 or later)
- LiDAR sensor recommended for best results

## Planned API

```dart
import 'package:flutter_object_capture/flutter_object_capture.dart';

// 1. Check support
final supported = await FlutterObjectCapture.isSupported();

// 2. Capture photos around an object (guided UI)
final capture = await FlutterObjectCapture.captureObject(
  configuration: const ObjectCaptureConfiguration(
    isObjectMaskingEnabled: true,
    isOverCaptureEnabled: false,
  ),
);

// 3. Reconstruct a USDZ model from the captured photos
final model = await FlutterObjectCapture.reconstruct(
  imagesPath: capture.imagesFolderPath,
  detailLevel: DetailLevel.medium,
);

print('USDZ written to ${model.modelPath}');

// 4. Listen to capture progress
FlutterObjectCapture.events.listen((event) {
  print('${event.state}: ${event.progress}');
});
```

## Detail levels

`DetailLevel` mirrors Apple's `PhotogrammetrySession.Request.Detail` quality presets:

| Level | Polygon count | Texture | Typical use |
| --- | --- | --- | --- |
| `preview` | very low | low res | quick on-device preview |
| `reduced` | low | medium | mobile AR display |
| `medium` | medium | high | default for most apps |
| `full` | high | high | desktop visualization |
| `raw` | unbounded | unprocessed | post-processing pipelines |

## Status

| Feature | Dart API | iOS native |
| --- | --- | --- |
| `isSupported()` | scaffolded | not implemented |
| `captureObject()` | scaffolded | not implemented |
| `reconstruct()` | scaffolded | not implemented |
| `events` stream | scaffolded | not implemented |

The native implementation will land in subsequent releases. See [`CHANGELOG.md`](CHANGELOG.md) for progress.

## Roadmap

- [ ] Wire `ObjectCaptureSession` to method / event channels (iOS 17+).
- [ ] Wire `PhotogrammetrySession` reconstruction to a method channel.
- [ ] Surface progress events via the event channel.
- [ ] Add an example app (capture → reconstruct → preview USDZ).
- [ ] macOS desktop reconstruction path (`PhotogrammetrySession` on macOS 12+).
- [ ] Resume / restore an interrupted capture session.

## License

[MIT](LICENSE)
