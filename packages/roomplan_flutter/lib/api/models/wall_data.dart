import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';


/// Represents a detected wall surface.
class WallData {
  /// A unique identifier for the wall.
  final String uuid;

  /// The 3D position of the wall's center.
  final Position position;

  /// A list of 3D points that define the perimeter of the wall.
  final List<Position> points;

  /// The width of the wall.
  final double width;

  /// The height of the wall.
  final double height;

  /// The confidence level of the detected wall.
  final Confidence confidence;

  /// A list of openings (doors or windows) detected in this wall.
  final List<OpeningData> openings;

  /// The detailed dimensions (width, height, depth) from the new API.
  final RoomDimensions? dimensions;

  /// The 3D transformation matrix (position, rotation) from the new API.
  final Matrix4? transform;

  /// Creates a [WallData].
  const WallData({
    required this.uuid,
    required this.position,
    required this.points,
    required this.width,
    required this.height,
    required this.confidence,
    required this.openings,
    this.dimensions,
    this.transform,
  });
  
  /// Creates a [WallData] from a JSON map.
  factory WallData.fromJson(Map<String, dynamic> json) {
    return WallData(
      uuid: json['uuid'] as String? ?? '',
      position: Position.fromJson(json['position'] as Map<String, dynamic>? ?? {}),
      points: (json['points'] as List<dynamic>?)
          ?.map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      confidence: Confidence.fromJson(json['confidence'] as String? ?? 'low'),
      openings: (json['openings'] as List<dynamic>?)
          ?.map((e) => OpeningData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      dimensions: json['dimensions'] != null
          ? RoomDimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : null,
      transform: json['transform'] != null
          ? _matrixFromJson(json['transform'] as List<dynamic>)
          : null,
    );
  }
  
  /// Converts this [WallData] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'position': position.toJson(),
      'points': points.map((e) => e.toJson()).toList(),
      'width': width,
      'height': height,
      'confidence': confidence.toJson(),
      'openings': openings.map((e) => e.toJson()).toList(),
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
    
    return other is WallData &&
        other.uuid == uuid &&
        other.position == position &&
        _listEquals(other.points, points) &&
        other.width == width &&
        other.height == height &&
        other.confidence == confidence &&
        _listEquals(other.openings, openings) &&
        other.dimensions == dimensions;
  }
  
  @override
  int get hashCode => Object.hash(
    uuid,
    position,
    points,
    width,
    height,
    confidence,
    openings,
    dimensions,
  );
  
  @override
  String toString() {
    return 'WallData(uuid: $uuid, width: ${width.toStringAsFixed(2)}, '
           'height: ${height.toStringAsFixed(2)}, openings: ${openings.length})';
  }
  
  /// Helper method to compare lists for equality.
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
