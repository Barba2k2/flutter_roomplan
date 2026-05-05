/// Lifecycle states of an [ObjectCaptureSession][1] running on iOS.
///
/// Mirrors `ObjectCaptureSession.CaptureState` from RealityKit.
///
/// [1]: https://developer.apple.com/documentation/realitykit/objectcapturesession
enum CaptureState {
  /// The session is being configured.
  initializing,

  /// The session is ready but capture has not started.
  ready,

  /// The system is locating and bounding the target object.
  detecting,

  /// Photos are actively being captured around the object.
  capturing,

  /// Capture has completed and the session is finalizing photo storage.
  finishing,

  /// All capture work is done; photos are available on disk.
  completed,

  /// The session ended in an error state.
  failed,
}
