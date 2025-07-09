import 'package:roomplan_flutter/roomplan_flutter.dart';

/// The type of opening detected.
enum OpeningType {
  /// A door opening.
  door,

  /// A window opening.
  window,
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

  /// Creates an [OpeningData].
  const OpeningData({
    required this.uuid,
    required this.type,
    required this.position,
    required this.width,
    required this.height,
    required this.confidence,
  });
}
