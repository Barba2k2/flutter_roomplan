/// Configuration options passed to [FlutterObjectCapture.captureObject].
///
/// Mirrors the configurable surface of `ObjectCaptureSession.Configuration`
/// from RealityKit on iOS 17+.
class ObjectCaptureConfiguration {
  const ObjectCaptureConfiguration({
    this.isOverCaptureEnabled = false,
    this.checkpointDirectory,
  });

  /// Whether to capture an extra "over capture" pass with additional
  /// close-up photos. Increases capture time and output size, but improves
  /// reconstruction quality.
  final bool isOverCaptureEnabled;

  /// Directory where the session writes its intermediate checkpoints.
  ///
  /// When null, a temporary directory is allocated automatically. Provide a
  /// stable path to allow resuming an interrupted session from disk.
  final String? checkpointDirectory;

  Map<String, Object?> toJson() => {
        'isOverCaptureEnabled': isOverCaptureEnabled,
        if (checkpointDirectory != null)
          'checkpointDirectory': checkpointDirectory,
      };
}
