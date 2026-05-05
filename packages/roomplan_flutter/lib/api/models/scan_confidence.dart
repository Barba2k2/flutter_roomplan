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
  
  /// Creates a [ScanConfidence] from a JSON map.
  factory ScanConfidence.fromJson(Map<String, dynamic> json) {
    return ScanConfidence(
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      wallAccuracy: (json['wallAccuracy'] as num?)?.toDouble() ?? 0.0,
      dimensionAccuracy: (json['dimensionAccuracy'] as num?)?.toDouble() ?? 0.0,
      warnings: (json['warnings'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
  
  /// Converts this [ScanConfidence] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'wallAccuracy': wallAccuracy,
      'dimensionAccuracy': dimensionAccuracy,
      'warnings': warnings,
    };
  }
  
  /// Creates a copy of this confidence with modified values.
  ScanConfidence copyWith({
    double? overall,
    double? wallAccuracy,
    double? dimensionAccuracy,
    List<String>? warnings,
  }) {
    return ScanConfidence(
      overall: overall ?? this.overall,
      wallAccuracy: wallAccuracy ?? this.wallAccuracy,
      dimensionAccuracy: dimensionAccuracy ?? this.dimensionAccuracy,
      warnings: warnings ?? this.warnings,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ScanConfidence &&
        other.overall == overall &&
        other.wallAccuracy == wallAccuracy &&
        other.dimensionAccuracy == dimensionAccuracy &&
        _listEquals(other.warnings, warnings);
  }
  
  @override
  int get hashCode => Object.hash(overall, wallAccuracy, dimensionAccuracy, warnings);
  
  @override
  String toString() {
    return 'ScanConfidence(overall: ${(overall * 100).toStringAsFixed(1)}%, '
           'wallAccuracy: ${(wallAccuracy * 100).toStringAsFixed(1)}%, '
           'dimensionAccuracy: ${(dimensionAccuracy * 100).toStringAsFixed(1)}%)';
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
