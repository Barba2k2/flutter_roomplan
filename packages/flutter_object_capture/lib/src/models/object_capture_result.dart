/// Outcome of a guided object-capture session.
///
/// Returned by [FlutterObjectCapture.captureObject] after the user finishes
/// walking around the target object. The captured photos are written to
/// [imagesFolderPath] and can be passed to [FlutterObjectCapture.reconstruct]
/// to produce a 3D model.
class ObjectCaptureResult {
  const ObjectCaptureResult({
    required this.imagesFolderPath,
    required this.captureCount,
    required this.startedAt,
    required this.completedAt,
  });

  /// Filesystem path to the folder containing the captured images.
  final String imagesFolderPath;

  /// Number of photos written to [imagesFolderPath].
  final int captureCount;

  /// When the capture session began.
  final DateTime startedAt;

  /// When the capture session finished (i.e. all photos were written).
  final DateTime completedAt;

  /// Total wall-clock duration of the capture session.
  Duration get duration => completedAt.difference(startedAt);

  factory ObjectCaptureResult.fromJson(Map<String, Object?> json) {
    return ObjectCaptureResult(
      imagesFolderPath: json['imagesFolderPath']! as String,
      captureCount: (json['captureCount']! as num).toInt(),
      startedAt: DateTime.parse(json['startedAt']! as String),
      completedAt: DateTime.parse(json['completedAt']! as String),
    );
  }
}
