/// Represents the dimensions of a scanned room.
class RoomDimensions {
  /// The width of the room.
  final double width;

  /// The height of the room.
  final double height;

  /// The length (depth) of the room.
  final double length;

  /// Creates a [RoomDimensions] object.
  const RoomDimensions({
    required this.width,
    required this.height,
    required this.length,
  });
}
