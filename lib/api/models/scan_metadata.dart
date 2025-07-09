
/// Contains metadata about the scanning session.
class ScanMetadata {
  /// The date and time when the scan was initiated.
  final DateTime scanDate;

  /// The total duration of the scanning process.
  final Duration scanDuration;

  /// The model of the device used for the scan (e.g., "iPhone14,3").
  final String deviceModel;

  /// Indicates whether the device has a LiDAR sensor, which affects accuracy.
  final bool hasLidar;

  /// Creates a [ScanMetadata] object.
  const ScanMetadata({
    required this.scanDate,
    required this.scanDuration,
    required this.deviceModel,
    required this.hasLidar,
  });
}
