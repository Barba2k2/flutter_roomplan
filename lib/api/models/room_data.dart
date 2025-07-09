import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Represents the complete scanned data of a single room.
class RoomData {
  /// The estimated dimensions of the room.
  /// This may be null if the dimensions could not be determined.
  final RoomDimensions? dimensions;

  /// A list of all detected wall surfaces in the room.
  final List<WallData> walls;

  /// A list of all detected objects in the room.
  final List<ObjectData> objects;

  /// A list of all detected doors in the room.
  final List<OpeningData> doors;

  /// A list of all detected windows in the room.
  final List<OpeningData> windows;

  /// Creates a [RoomData].
  const RoomData({
    this.dimensions,
    required this.walls,
    required this.objects,
    required this.doors,
    required this.windows,
  });
}
