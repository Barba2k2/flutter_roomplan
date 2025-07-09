import 'package:roomplan_flutter/roomplan_flutter.dart';

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
  unknown,
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

  /// Creates an [ObjectData].
  const ObjectData({
    required this.uuid,
    required this.position,
    required this.category,
    required this.width,
    required this.height,
    required this.length,
    required this.confidence,
  });
}
