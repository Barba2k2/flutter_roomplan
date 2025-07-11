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
}
