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
}
