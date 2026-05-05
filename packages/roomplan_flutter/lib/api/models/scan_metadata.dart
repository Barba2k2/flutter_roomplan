
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
  
  /// Creates a [ScanMetadata] from a JSON map.
  factory ScanMetadata.fromJson(Map<String, dynamic> json) {
    return ScanMetadata(
      scanDate: json['scanDate'] != null 
          ? DateTime.parse(json['scanDate'] as String)
          : DateTime.now(),
      scanDuration: Duration(
        microseconds: ((json['scanDuration'] as num?)?.toDouble() ?? 0.0 * 1000000).round(),
      ),
      deviceModel: json['deviceModel'] as String? ?? 'Unknown',
      hasLidar: json['hasLidar'] as bool? ?? false,
    );
  }
  
  /// Converts this [ScanMetadata] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'scanDate': scanDate.toIso8601String(),
      'scanDuration': scanDuration.inMicroseconds / 1000000.0,
      'deviceModel': deviceModel,
      'hasLidar': hasLidar,
    };
  }
  
  /// Creates a copy of this metadata with modified values.
  ScanMetadata copyWith({
    DateTime? scanDate,
    Duration? scanDuration,
    String? deviceModel,
    bool? hasLidar,
  }) {
    return ScanMetadata(
      scanDate: scanDate ?? this.scanDate,
      scanDuration: scanDuration ?? this.scanDuration,
      deviceModel: deviceModel ?? this.deviceModel,
      hasLidar: hasLidar ?? this.hasLidar,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ScanMetadata &&
        other.scanDate == scanDate &&
        other.scanDuration == scanDuration &&
        other.deviceModel == deviceModel &&
        other.hasLidar == hasLidar;
  }
  
  @override
  int get hashCode => Object.hash(scanDate, scanDuration, deviceModel, hasLidar);
  
  @override
  String toString() {
    return 'ScanMetadata(scanDate: $scanDate, '
           'scanDuration: ${scanDuration.inSeconds}s, '
           'deviceModel: $deviceModel, '
           'hasLidar: $hasLidar)';
  }
}
