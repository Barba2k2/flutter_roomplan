/// Represents the confidence levels of various aspects of the scan.
///
/// Confidence values range from 0.0 (low) to 1.0 (high).
class ScanConfidence {
  /// The overall confidence in the quality of the entire scan.
  final double overall;

  /// The confidence in the accuracy of the detected wall surfaces.
  final double wallAccuracy;

  /// The confidence in the accuracy of the dimensional measurements.
  final double dimensionAccuracy;

  /// A list of warnings or issues encountered during the scan that may affect quality.
  /// (Not yet implemented in the native layer).
  final List<String> warnings;

  /// Creates a [ScanConfidence] object.
  const ScanConfidence({
    required this.overall,
    required this.wallAccuracy,
    required this.dimensionAccuracy,
    this.warnings = const [],
  });
}
