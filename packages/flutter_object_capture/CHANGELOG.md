## 0.0.1

- Initial scaffold: package layout, iOS plugin registration (`flutter_object_capture/method_channel`, `flutter_object_capture/event_channel`), example app. 
- Dart API: `ObjectCaptureProcessor` (`isSupported`, `getLimits`, `reconstruct` as a stream of sealed `ReconstructionEvent`s, `cancel`, `dispose`), `ObjectCaptureConfiguration` (`FeatureSensitivity`, `SampleOrdering`), `ObjectCaptureLimits`, typed exceptions, `.usdz` output path validation.
- iOS native layer: `ObjectCaptureController` (one `PhotogrammetrySession` per job, `.reduced` USDZ output, progress/sample/notice/completed events on the main thread, cancel and error mapping), `ObjectCaptureOutputConverter`, `ObjectCaptureErrorMapper`, `#if canImport(RealityKit)` fallback answering `not_supported`. Not yet run on a device.
