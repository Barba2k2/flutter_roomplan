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
