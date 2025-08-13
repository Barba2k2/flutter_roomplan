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

  /// A list of all detected openings in the room.
  final List<OpeningData> openings;

  /// The detected floor surface, if available.
  final WallData? floor;

  /// The detected ceiling surface, if available.
  final WallData? ceiling;

  /// Creates a [RoomData].
  const RoomData({
    this.dimensions,
    required this.walls,
    required this.objects,
    required this.doors,
    required this.windows,
    required this.openings,
    this.floor,
    this.ceiling,
  });
  
  /// Creates a [RoomData] from a JSON map.
  factory RoomData.fromJson(Map<String, dynamic> json) {
    return RoomData(
      dimensions: json['dimensions'] != null
          ? RoomDimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : null,
      walls: (json['walls'] as List<dynamic>?)
          ?.map((e) => WallData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      objects: (json['objects'] as List<dynamic>?)
          ?.map((e) => ObjectData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      doors: (json['doors'] as List<dynamic>?)
          ?.map((e) => OpeningData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      windows: (json['windows'] as List<dynamic>?)
          ?.map((e) => OpeningData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      openings: (json['openings'] as List<dynamic>?)
          ?.map((e) => OpeningData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      floor: json['floor'] != null
          ? WallData.fromJson(json['floor'] as Map<String, dynamic>)
          : null,
      ceiling: json['ceiling'] != null
          ? WallData.fromJson(json['ceiling'] as Map<String, dynamic>)
          : null,
    );
  }
  
  /// Converts this [RoomData] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'dimensions': dimensions?.toJson(),
      'walls': walls.map((e) => e.toJson()).toList(),
      'objects': objects.map((e) => e.toJson()).toList(),
      'doors': doors.map((e) => e.toJson()).toList(),
      'windows': windows.map((e) => e.toJson()).toList(),
      'openings': openings.map((e) => e.toJson()).toList(),
      'floor': floor?.toJson(),
      'ceiling': ceiling?.toJson(),
    };
  }
  
  /// Creates a copy of this room data with modified values.
  RoomData copyWith({
    RoomDimensions? dimensions,
    List<WallData>? walls,
    List<ObjectData>? objects,
    List<OpeningData>? doors,
    List<OpeningData>? windows,
    List<OpeningData>? openings,
    WallData? floor,
    WallData? ceiling,
  }) {
    return RoomData(
      dimensions: dimensions ?? this.dimensions,
      walls: walls ?? this.walls,
      objects: objects ?? this.objects,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      openings: openings ?? this.openings,
      floor: floor ?? this.floor,
      ceiling: ceiling ?? this.ceiling,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is RoomData &&
        other.dimensions == dimensions &&
        _listEquals(other.walls, walls) &&
        _listEquals(other.objects, objects) &&
        _listEquals(other.doors, doors) &&
        _listEquals(other.windows, windows) &&
        _listEquals(other.openings, openings) &&
        other.floor == floor &&
        other.ceiling == ceiling;
  }
  
  @override
  int get hashCode => Object.hash(
    dimensions,
    walls,
    objects,
    doors,
    windows,
    openings,
    floor,
    ceiling,
  );
  
  @override
  String toString() {
    return 'RoomData(dimensions: $dimensions, walls: ${walls.length}, '
           'objects: ${objects.length}, doors: ${doors.length}, '
           'windows: ${windows.length}, openings: ${openings.length})';
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
