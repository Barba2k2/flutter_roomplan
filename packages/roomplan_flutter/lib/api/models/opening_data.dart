import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';

/// The type of opening detected.
enum OpeningType {
  /// A door opening.
  door,

  /// A window opening.
  window,

  /// A generic opening.
  opening;
  
  /// Creates an [OpeningType] from a JSON string.
  static OpeningType fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'door':
        return OpeningType.door;
      case 'window':
        return OpeningType.window;
      case 'opening':
        return OpeningType.opening;
      default:
        return OpeningType.opening;
    }
  }
  
  /// Converts this [OpeningType] to a JSON string.
  String toJson() => name;
}

/// Represents a detected opening in a wall, which can be a door or a window.
class OpeningData {
  /// A unique identifier for the opening.
  final String uuid;

  /// The type of opening (door or window).
  final OpeningType type;

  /// The 3D position of the opening.
  final Position position;

  /// The width of the opening.
  final double width;

  /// The height of the opening.
  final double height;

  /// The confidence level of the detected opening.
  final Confidence confidence;

  /// The detailed dimensions (width, height, depth) from the new API.
  final RoomDimensions? dimensions;

  /// The 3D transformation matrix (position, rotation) from the new API.
  final Matrix4? transform;

  /// Creates an [OpeningData].
  const OpeningData({
    required this.uuid,
    required this.type,
    required this.position,
    required this.width,
    required this.height,
    required this.confidence,
    this.dimensions,
    this.transform,
  });
  
  /// Creates an [OpeningData] from a JSON map.
  factory OpeningData.fromJson(Map<String, dynamic> json) {
    return OpeningData(
      uuid: json['uuid'] as String? ?? '',
      type: OpeningType.fromJson(json['type'] as String? ?? 'opening'),
      position: Position.fromJson(json['position'] as Map<String, dynamic>? ?? {}),
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      confidence: Confidence.fromJson(json['confidence'] as String? ?? 'low'),
      dimensions: json['dimensions'] != null
          ? RoomDimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : null,
      transform: json['transform'] != null
          ? _matrixFromJson(json['transform'] as List<dynamic>)
          : null,
    );
  }
  
  /// Converts this [OpeningData] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'type': type.toJson(),
      'position': position.toJson(),
      'width': width,
      'height': height,
      'confidence': confidence.toJson(),
      'dimensions': dimensions?.toJson(),
      'transform': transform != null ? _matrixToJson(transform!) : null,
    };
  }
  
  /// Helper method to convert Matrix4 to JSON-serializable list.
  static List<double> _matrixToJson(Matrix4 matrix) {
    return matrix.storage.toList();
  }
  
  /// Helper method to convert JSON list to Matrix4.
  static Matrix4 _matrixFromJson(List<dynamic> data) {
    final storage = data.cast<double>();
    return Matrix4.fromList(storage);
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OpeningData &&
        other.uuid == uuid &&
        other.type == type &&
        other.position == position &&
        other.width == width &&
        other.height == height &&
        other.confidence == confidence &&
        other.dimensions == dimensions;
  }
  
  @override
  int get hashCode => Object.hash(
    uuid,
    type,
    position,
    width,
    height,
    confidence,
    dimensions,
  );
  
  @override
  String toString() {
    return 'OpeningData(uuid: $uuid, type: $type, '
           'width: ${width.toStringAsFixed(2)}, height: ${height.toStringAsFixed(2)})';
  }
}
