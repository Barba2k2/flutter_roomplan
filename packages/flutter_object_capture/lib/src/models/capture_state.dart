/// Lifecycle states reported by the plugin.
///
/// The first seven values mirror `ObjectCaptureSession.CaptureState` from
/// RealityKit on iOS 17+ and describe a guided photo-capture session.
/// [CaptureState.reconstructing] is plugin-specific and is emitted while a
/// `PhotogrammetrySession` is processing photos into a 3D model.
///
/// See also:
/// https://developer.apple.com/documentation/realitykit/objectcapturesession
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

  /// A `PhotogrammetrySession` is processing captured images into a 3D model.
  /// Emitted by [FlutterObjectCapture.reconstruct].
  reconstructing,
}
