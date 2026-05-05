/// Configuration options for room scanning sessions.
///
/// This class allows you to customize various aspects of the scanning process
/// including quality settings, timeout values, and feature detection preferences.
class ScanConfiguration {
  /// The quality level for room scanning.
  final ScanQuality quality;
  
  /// Maximum duration for a scanning session in seconds.
  /// If null, no timeout is applied.
  final int? timeoutSeconds;
  
  /// Whether to enable real-time updates during scanning.
  final bool enableRealtimeUpdates;
  
  /// Whether to detect and include furniture objects in the scan.
  final bool detectFurniture;
  
  /// Whether to detect and include doors in the scan.
  final bool detectDoors;
  
  /// Whether to detect and include windows in the scan.
  final bool detectWindows;
  
  /// Minimum confidence level for detected objects to be included.
  final double minimumConfidence;
  
  /// Whether to enable advanced surface detection.
  final bool enableAdvancedSurfaceDetection;
  
  /// Creates a scan configuration with the specified settings.
  const ScanConfiguration({
    this.quality = ScanQuality.balanced,
    this.timeoutSeconds,
    this.enableRealtimeUpdates = true,
    this.detectFurniture = true,
    this.detectDoors = true,
    this.detectWindows = true,
    this.minimumConfidence = 0.5,
    this.enableAdvancedSurfaceDetection = false,
  }) : assert(minimumConfidence >= 0.0 && minimumConfidence <= 1.0,
             'minimumConfidence must be between 0.0 and 1.0');
  
  /// Creates a configuration optimized for speed.
  const ScanConfiguration.fast({
    this.timeoutSeconds = 60,
    this.enableRealtimeUpdates = false,
    this.detectFurniture = false,
    this.detectDoors = true,
    this.detectWindows = true,
    this.minimumConfidence = 0.3,
    this.enableAdvancedSurfaceDetection = false,
  }) : quality = ScanQuality.fast;
  
  /// Creates a configuration optimized for accuracy.
  const ScanConfiguration.accurate({
    this.timeoutSeconds = 300,
    this.enableRealtimeUpdates = true,
    this.detectFurniture = true,
    this.detectDoors = true,
    this.detectWindows = true,
    this.minimumConfidence = 0.8,
    this.enableAdvancedSurfaceDetection = true,
  }) : quality = ScanQuality.high;
  
  /// Creates a configuration with minimal features for basic room outline.
  const ScanConfiguration.minimal({
    this.timeoutSeconds = 120,
    this.enableRealtimeUpdates = false,
    this.detectFurniture = false,
    this.detectDoors = false,
    this.detectWindows = false,
    this.minimumConfidence = 0.7,
    this.enableAdvancedSurfaceDetection = false,
  }) : quality = ScanQuality.balanced;
  
  /// Converts the configuration to a map for native platform communication.
  Map<String, dynamic> toMap() {
    return {
      'quality': quality.name,
      'timeoutSeconds': timeoutSeconds,
      'enableRealtimeUpdates': enableRealtimeUpdates,
      'detectFurniture': detectFurniture,
      'detectDoors': detectDoors,
      'detectWindows': detectWindows,
      'minimumConfidence': minimumConfidence,
      'enableAdvancedSurfaceDetection': enableAdvancedSurfaceDetection,
    };
  }
  
  /// Creates a configuration from a map.
  factory ScanConfiguration.fromMap(Map<String, dynamic> map) {
    return ScanConfiguration(
      quality: ScanQuality.values.firstWhere(
        (q) => q.name == map['quality'],
        orElse: () => ScanQuality.balanced,
      ),
      timeoutSeconds: map['timeoutSeconds'] as int?,
      enableRealtimeUpdates: map['enableRealtimeUpdates'] as bool? ?? true,
      detectFurniture: map['detectFurniture'] as bool? ?? true,
      detectDoors: map['detectDoors'] as bool? ?? true,
      detectWindows: map['detectWindows'] as bool? ?? true,
      minimumConfidence: (map['minimumConfidence'] as num?)?.toDouble() ?? 0.5,
      enableAdvancedSurfaceDetection: map['enableAdvancedSurfaceDetection'] as bool? ?? false,
    );
  }
  
  /// Creates a copy of this configuration with modified values.
  ScanConfiguration copyWith({
    ScanQuality? quality,
    int? timeoutSeconds,
    bool? enableRealtimeUpdates,
    bool? detectFurniture,
    bool? detectDoors,
    bool? detectWindows,
    double? minimumConfidence,
    bool? enableAdvancedSurfaceDetection,
  }) {
    return ScanConfiguration(
      quality: quality ?? this.quality,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      enableRealtimeUpdates: enableRealtimeUpdates ?? this.enableRealtimeUpdates,
      detectFurniture: detectFurniture ?? this.detectFurniture,
      detectDoors: detectDoors ?? this.detectDoors,
      detectWindows: detectWindows ?? this.detectWindows,
      minimumConfidence: minimumConfidence ?? this.minimumConfidence,
      enableAdvancedSurfaceDetection: enableAdvancedSurfaceDetection ?? this.enableAdvancedSurfaceDetection,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ScanConfiguration &&
        other.quality == quality &&
        other.timeoutSeconds == timeoutSeconds &&
        other.enableRealtimeUpdates == enableRealtimeUpdates &&
        other.detectFurniture == detectFurniture &&
        other.detectDoors == detectDoors &&
        other.detectWindows == detectWindows &&
        other.minimumConfidence == minimumConfidence &&
        other.enableAdvancedSurfaceDetection == enableAdvancedSurfaceDetection;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      quality,
      timeoutSeconds,
      enableRealtimeUpdates,
      detectFurniture,
      detectDoors,
      detectWindows,
      minimumConfidence,
      enableAdvancedSurfaceDetection,
    );
  }
  
  @override
  String toString() {
    return 'ScanConfiguration('
        'quality: $quality, '
        'timeoutSeconds: $timeoutSeconds, '
        'enableRealtimeUpdates: $enableRealtimeUpdates, '
        'detectFurniture: $detectFurniture, '
        'detectDoors: $detectDoors, '
        'detectWindows: $detectWindows, '
        'minimumConfidence: $minimumConfidence, '
        'enableAdvancedSurfaceDetection: $enableAdvancedSurfaceDetection)';
  }
}

/// Quality levels for room scanning.
enum ScanQuality {
  /// Fast scanning with lower accuracy.
  /// Suitable for quick previews or when battery life is a concern.
  fast,
  
  /// Balanced scanning with moderate accuracy and speed.
  /// Good default choice for most use cases.
  balanced,
  
  /// High-quality scanning with maximum accuracy.
  /// Takes longer but provides the most detailed results.
  high;
  
  /// Human-readable description of the quality level.
  String get description {
    switch (this) {
      case ScanQuality.fast:
        return 'Fast scanning with lower accuracy';
      case ScanQuality.balanced:
        return 'Balanced scanning with moderate accuracy and speed';
      case ScanQuality.high:
        return 'High-quality scanning with maximum accuracy';
    }
  }
}