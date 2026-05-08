# flutter_object_capture

[![pub package](https://img.shields.io/badge/pub-pending-lightgrey.svg)](https://pub.dev/)
[![status](https://img.shields.io/badge/status-alpha-yellow.svg)](#status)

Flutter plugin for Apple's [RealityKit Object Capture](https://developer.apple.com/documentation/realitykit/photogrammetrysession) — guided photo capture and on-device photogrammetry that turns a set of images into a textured USDZ 3D model on iOS.

> **Status:** Alpha (`v0.0.2`). Both `ObjectCaptureSession` and `PhotogrammetrySession` are wired through to Dart. The plugin has not yet been validated end-to-end on a physical device — expect rough edges and please file issues. **Do not ship to production yet.**

## Why this package

Apple's Object Capture has two pieces:

1. **`ObjectCaptureSession`** (iOS 17+) — a guided UI that walks the user around an object while taking optimally-spaced photos.
2. **`PhotogrammetrySession`** (iOS 17+ on-device, also macOS 12+ desktop) — reconstructs a textured 3D mesh from those photos.

This plugin wraps both, exposing a clean Dart API for Flutter apps. It pairs naturally with [`roomplan_flutter`](../roomplan_flutter) — RoomPlan returns furniture as bounding boxes; Object Capture lets you replace those boxes with photorealistic meshes.

## Requirements

- iOS 17.0+
- A device with the A14 Bionic chip or newer (iPhone 12 Pro / iPad Pro 2020 or later)
- LiDAR sensor recommended for best results

## Example

A working demo lives in the monorepo's shared example app at
[`/example`](https://github.com/Barba2k2/flutter_roomplan/tree/master/example)
— it covers Object Capture alongside the other plugins in this family.
Run it with:

```bash
cd example
flutter run
```

## Setup

### Info.plist

The user must grant camera access for guided capture. Add to your app's
`ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Used to capture photos of the object you want to scan.</string>
```

### iOS deployment target

The plugin requires iOS 17+. Make sure your `Podfile` (CocoaPods) or your
project settings (Swift Package Manager) declare `platform :ios, '17.0'`
or later.

## Usage

```dart
import 'package:flutter_object_capture/flutter_object_capture.dart';

// 1. Check support (iOS 17+, A14 Bionic or newer with LiDAR)
final supported = await FlutterObjectCapture.isSupported();

// 2. Capture photos around an object (guided full-screen UI)
final capture = await FlutterObjectCapture.captureObject(
  configuration: const ObjectCaptureConfiguration(
    isOverCaptureEnabled: false,
  ),
);

// 3. Reconstruct a USDZ model from the captured photos
final model = await FlutterObjectCapture.reconstruct(
  imagesPath: capture.imagesFolderPath,
  detailLevel: DetailLevel.medium,
);

print('USDZ written to ${model.modelPath}');

// 4. Listen to progress (capture state changes + photogrammetry progress)
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
| `isSupported()` | shipped | shipped |
| `captureObject()` | shipped | shipped (alpha) |
| `reconstruct()` | shipped | shipped (alpha) |
| `events` stream | shipped | shipped |

Both `ObjectCaptureSession` and `PhotogrammetrySession` are wired
through. The native flow has not been validated end-to-end on a real
device yet — bugs are expected. See [`CHANGELOG.md`](CHANGELOG.md) for
progress.

## Roadmap

- [x] Wire `ObjectCaptureSession` to method / event channels (iOS 17+).
- [x] Wire `PhotogrammetrySession` reconstruction to a method channel.
- [x] Surface progress events via the event channel.
- [ ] Validate the full pipeline on a physical iPhone 12 Pro / 15 Pro device.
- [ ] Add an example app (capture → reconstruct → preview USDZ).
- [ ] Customisable capture UI (replace the bundled SwiftUI overlay).
- [ ] macOS desktop reconstruction path (`PhotogrammetrySession` on macOS 12+).
- [ ] Resume / restore an interrupted capture session.

## License

[MIT](LICENSE)
