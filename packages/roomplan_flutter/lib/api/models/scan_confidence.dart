/// Represents the confidence levels of various aspects of the scan.
///
/// Confidence values range from 0.0 (low) to 1.0 (high).
class ScanConfidence {
  /// The overall confidence in the quality of the entire scan.
  final double overall;

  /// The confidence in the accuracy of the detected wall surfaces.
  final double wallAccuracy;

  /// Creates a [ScanConfidence] object.
  const ScanConfidence({
    required this.overall,
    required this.wallAccuracy,
  });

  /// Creates a [ScanConfidence] from a JSON map.
  factory ScanConfidence.fromJson(Map<String, dynamic> json) {
    return ScanConfidence(
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      wallAccuracy: (json['wallAccuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts this [ScanConfidence] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'wallAccuracy': wallAccuracy,
    };
  }

  /// Creates a copy of this confidence with modified values.
  ScanConfidence copyWith({
    double? overall,
    double? wallAccuracy,
  }) {
    return ScanConfidence(
      overall: overall ?? this.overall,
      wallAccuracy: wallAccuracy ?? this.wallAccuracy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScanConfidence &&
        other.overall == overall &&
        other.wallAccuracy == wallAccuracy;
  }

  @override
  int get hashCode => Object.hash(overall, wallAccuracy);

  @override
  String toString() {
    return 'ScanConfidence(overall: ${(overall * 100).toStringAsFixed(1)}%, '
        'wallAccuracy: ${(wallAccuracy * 100).toStringAsFixed(1)}%)';
  }
}
