## 0.0.1

- Initial scaffold: package layout, iOS plugin registration (`flutter_object_capture/method_channel`, `flutter_object_capture/event_channel`), example app. 
- Dart API: `ObjectCaptureProcessor` (`isSupported`, `getLimits`, `reconstruct` as a stream of sealed `ReconstructionEvent`s, `cancel`, `dispose`), `ObjectCaptureConfiguration` (`FeatureSensitivity`, `SampleOrdering`), `ObjectCaptureLimits`, typed exceptions, `.usdz` output path validation. Native reconstruction is not implemented yet.
