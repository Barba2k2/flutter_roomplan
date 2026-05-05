/// Configuration options passed to [FlutterObjectCapture.captureObject].
///
/// Mirrors the configurable surface of `ObjectCaptureSession.Configuration`
/// from RealityKit on iOS 17+.
class ObjectCaptureConfiguration {
  const ObjectCaptureConfiguration({
    this.isObjectMaskingEnabled = true,
    this.isOverCaptureEnabled = false,
    this.checkpointDirectory,
  });

  /// Whether the system should mask the object from its background during
  /// capture. Improves reconstruction quality at a small performance cost.
  final bool isObjectMaskingEnabled;

  /// Whether to capture extra detail passes (e.g. additional close-up shots).
  /// Increases capture time and output size.
  final bool isOverCaptureEnabled;

  /// Directory where intermediate checkpoints are stored. When provided, an
  /// interrupted session can be resumed from the same directory.
  final String? checkpointDirectory;

  Map<String, Object?> toJson() => {
        'isObjectMaskingEnabled': isObjectMaskingEnabled,
        'isOverCaptureEnabled': isOverCaptureEnabled,
        if (checkpointDirectory != null)
          'checkpointDirectory': checkpointDirectory,
      };
}
