import 'package:vector_math/vector_math_64.dart';

/// Represents a 3D position vector.
class Position {
  /// The underlying 3D vector.
  final Vector3 vector;

  /// The x-coordinate.
  double get x => vector.x;

  /// The y-coordinate.
  double get y => vector.y;

  /// The z-coordinate.
  double get z => vector.z;

  /// Creates a [Position] from a [Vector3].
  const Position(this.vector);
  
  /// Creates a [Position] from coordinates.
  Position.fromCoordinates(double x, double y, double z) : vector = Vector3(x, y, z);
  
  /// Creates a [Position] from a JSON map.
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position.fromCoordinates(
      (json['x'] as num?)?.toDouble() ?? 0.0,
      (json['y'] as num?)?.toDouble() ?? 0.0,
      (json['z'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  /// Converts this [Position] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.vector == vector;
  }
  
  @override
  int get hashCode => vector.hashCode;
  
  @override
  String toString() => 'Position(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)})';
}
