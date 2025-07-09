/// Represents the dimensions of an object or room from the native RoomPlan API.
///
/// This is an internal model and should not be used publicly.
class RoomDimensions {
  /// The width, typically along the x-axis.
  final double width;

  /// The height, typically along the y-axis.
  final double height;

  /// The depth or length, typically along the z-axis.
  final double depth;

  /// Creates an internal [RoomDimensions] object.
  RoomDimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  /// Creates [RoomDimensions] from a list of numbers (usually [width, height, depth]).
  factory RoomDimensions.fromList(List<dynamic> list) {
    if (list.isEmpty) {
      return RoomDimensions(width: 0, height: 0, depth: 0);
    }
    return RoomDimensions(
      width: (list[0] as num).toDouble(),
      height: (list.length > 1 ? list[1] as num : 0.0).toDouble(),
      depth: (list.length > 2 ? list[2] as num : 0.0).toDouble(),
    );
  }

  /// Creates [RoomDimensions] from a map (e.g., from JSON).
  factory RoomDimensions.fromMap(Map<String, dynamic> json) {
    return RoomDimensions(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
    );
  }

  /// Flexible constructor that handles both list and map JSON formats.
  factory RoomDimensions.fromJson(dynamic json) {
    if (json is List) {
      return RoomDimensions.fromList(json);
    } else if (json is Map<String, dynamic>) {
      return RoomDimensions.fromMap(json);
    }
    throw const FormatException('Invalid JSON for RoomDimensions');
  }

  /// Converts the object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'depth': depth,
    };
  }

  @override
  String toString() =>
      'W: ${width.toStringAsFixed(2)}m, H: ${height.toStringAsFixed(2)}m, D: ${depth.toStringAsFixed(2)}m';
}
