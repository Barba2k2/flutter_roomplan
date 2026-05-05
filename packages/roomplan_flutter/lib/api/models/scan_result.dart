import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Represents the final result of a successful room scan.
class ScanResult {
  /// The structured data of the scanned room, including walls and objects.
  final RoomData room;

  /// Metadata associated with the scanning session.
  final ScanMetadata metadata;

  /// Confidence levels for various aspects of the scan.
  final ScanConfidence confidence;

  /// Creates a [ScanResult] object.
  const ScanResult({
    required this.room,
    required this.metadata,
    required this.confidence,
  });
  
  /// Creates a [ScanResult] from a JSON map.
  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      room: RoomData.fromJson(json['room'] as Map<String, dynamic>? ?? {}),
      metadata: ScanMetadata.fromJson(json['metadata'] as Map<String, dynamic>? ?? {}),
      confidence: ScanConfidence.fromJson(json['confidence'] as Map<String, dynamic>? ?? {}),
    );
  }
  
  /// Converts this [ScanResult] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'room': room.toJson(),
      'metadata': metadata.toJson(),
      'confidence': confidence.toJson(),
    };
  }
  
  /// Creates a copy of this scan result with modified values.
  ScanResult copyWith({
    RoomData? room,
    ScanMetadata? metadata,
    ScanConfidence? confidence,
  }) {
    return ScanResult(
      room: room ?? this.room,
      metadata: metadata ?? this.metadata,
      confidence: confidence ?? this.confidence,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ScanResult &&
        other.room == room &&
        other.metadata == metadata &&
        other.confidence == confidence;
  }
  
  @override
  int get hashCode => Object.hash(room, metadata, confidence);
  
  @override
  String toString() {
    return 'ScanResult(room: $room, metadata: $metadata, confidence: $confidence)';
  }
}
