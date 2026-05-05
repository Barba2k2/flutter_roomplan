import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';

/// Pre-defined categories for scanned objects.
enum ObjectCategory {
  storage,
  table,
  sofa,
  chair,
  bed,
  sink,
  toilet,
  oven,
  refrigerator,
  stove,
  washerDryer,
  unknown;
  
  /// Creates an [ObjectCategory] from a JSON string.
  static ObjectCategory fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'storage':
        return ObjectCategory.storage;
      case 'table':
        return ObjectCategory.table;
      case 'sofa':
        return ObjectCategory.sofa;
      case 'chair':
        return ObjectCategory.chair;
      case 'bed':
        return ObjectCategory.bed;
      case 'sink':
        return ObjectCategory.sink;
      case 'toilet':
        return ObjectCategory.toilet;
      case 'oven':
        return ObjectCategory.oven;
      case 'refrigerator':
        return ObjectCategory.refrigerator;
      case 'stove':
        return ObjectCategory.stove;
      case 'washerdryer':
      case 'washer_dryer':
        return ObjectCategory.washerDryer;
      default:
        return ObjectCategory.unknown;
    }
  }
  
  /// Converts this [ObjectCategory] to a JSON string.
  String toJson() => name;
}

/// Represents a detected object within the scanned room.
class ObjectData {
  /// A unique identifier for the object.
  final String uuid;

  /// The 3D position of the object's center.
  final Position position;

  /// The category of the detected object.
  final ObjectCategory category;

  /// The width of the object.
  final double width;

  /// The height of the object.
  final double height;

  /// The length (depth) of the object.
  final double length;

  /// The confidence level of the detected object.
  final Confidence confidence;

  /// The detailed dimensions (width, height, depth) from the new API.
  final RoomDimensions? dimensions;

  /// The 3D transformation matrix (position, rotation) from the new API.
  final Matrix4? transform;

  /// Creates an [ObjectData].
  const ObjectData({
    required this.uuid,
    required this.position,
    required this.category,
    required this.width,
    required this.height,
    required this.length,
    required this.confidence,
    this.dimensions,
    this.transform,
  });
  
  /// Creates an [ObjectData] from a JSON map.
  factory ObjectData.fromJson(Map<String, dynamic> json) {
    return ObjectData(
      uuid: json['uuid'] as String? ?? '',
      position: Position.fromJson(json['position'] as Map<String, dynamic>? ?? {}),
      category: ObjectCategory.fromJson(json['category'] as String? ?? 'unknown'),
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      confidence: Confidence.fromJson(json['confidence'] as String? ?? 'low'),
      dimensions: json['dimensions'] != null
          ? RoomDimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : null,
      transform: json['transform'] != null
          ? _matrixFromJson(json['transform'] as List<dynamic>)
          : null,
    );
  }
  
  /// Converts this [ObjectData] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'position': position.toJson(),
      'category': category.toJson(),
      'width': width,
      'height': height,
      'length': length,
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
    
    return other is ObjectData &&
        other.uuid == uuid &&
        other.position == position &&
        other.category == category &&
        other.width == width &&
        other.height == height &&
        other.length == length &&
        other.confidence == confidence &&
        other.dimensions == dimensions;
  }
  
  @override
  int get hashCode => Object.hash(
    uuid,
    position,
    category,
    width,
    height,
    length,
    confidence,
    dimensions,
  );
  
  @override
  String toString() {
    return 'ObjectData(uuid: $uuid, category: $category, '
           'width: ${width.toStringAsFixed(2)}, height: ${height.toStringAsFixed(2)}, '
           'length: ${length.toStringAsFixed(2)})';
  }
}
