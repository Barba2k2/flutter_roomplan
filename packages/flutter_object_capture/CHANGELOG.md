## 0.0.2

* **Feature**: Native iOS implementation of `captureObject()`. The plugin now
  hosts a SwiftUI `ObjectCaptureView` inside a `UIHostingController`,
  presents it modally, drives the `ObjectCaptureSession` state machine
  (`startDetecting()`, `startCapturing()`, `beginNewScanPass()`, `finish()`,
  `cancel()`), and returns the captured images directory to Dart.
* **Feature**: Native iOS implementation of `reconstruct()`. Drives a
  `PhotogrammetrySession` against the captured images and writes a `.usdz`
  model at the requested `DetailLevel`. Progress is forwarded through the
  event channel.
* **Feature**: `events` stream now emits `CaptureEvent`s for every
  `ObjectCaptureSession` state transition and for photogrammetry progress
  (new `CaptureState.reconstructing`).
* **API**: Removed `ObjectCaptureConfiguration.isObjectMaskingEnabled`
  (it is not part of `ObjectCaptureSession.Configuration` on iOS 17). The
  remaining surface (`isOverCaptureEnabled`, `checkpointDirectory`) is
  unchanged.
* **Note**: The native pipeline has not yet been verified end-to-end on a
  physical device; expect bugs and please file issues.

## 0.0.1

* Initial scaffolding for the `flutter_object_capture` plugin.
* Public Dart API surface defined: `FlutterObjectCapture`, `ObjectCaptureConfiguration`,
  `ObjectCaptureResult`, `PhotogrammetryResult`, `CaptureEvent`, `CaptureState`,
  `DetailLevel`, and `ObjectCaptureException`.
* Method and event channels registered on the iOS side
  (`SwiftFlutterObjectCapturePlugin`); native implementation pending.
* iOS plugin ships with both a Swift Package Manager manifest
  (`ios/flutter_object_capture/Package.swift`) and a CocoaPods spec
  (`ios/flutter_object_capture.podspec`) backed by the same source tree.
* Not yet ready for production use.
