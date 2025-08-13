import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';

/// The type of opening detected.
enum OpeningType {
  /// A door opening.
  door,

  /// A window opening.
  window,

  /// A generic opening.
  opening,
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
}
