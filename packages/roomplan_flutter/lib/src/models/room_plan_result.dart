import 'room_dimensions.dart';
import 'wall_measurement.dart';
import 'object_measurement.dart';
import 'door_window_measurement.dart';

class RoomPlanResult {
  final bool success;
  final String message;
  final String captureDate;
  final String status;
  final List<WallMeasurement> walls;
  final List<ObjectMeasurement> objects;
  final List<DoorWindowMeasurement> doors;
  final List<DoorWindowMeasurement> windows;
  final RoomDimensions? roomDimensions;
  final Map<String, dynamic>? metadataInternal;
  final Map<String, dynamic>? confidenceInternal;

  RoomPlanResult({
    required this.success,
    required this.message,
    required this.captureDate,
    required this.status,
    required this.walls,
    required this.objects,
    required this.doors,
    required this.windows,
    this.roomDimensions,
    this.metadataInternal,
    this.confidenceInternal,
  });

  factory RoomPlanResult.fromJson(Map<String, dynamic> json) {
    RoomDimensions? roomDimensions;
    final floors = json['floors'] as List<dynamic>?;
    if (floors != null && floors.isNotEmpty) {
      final floorMap = floors.first as Map<String, dynamic>;
      final dims = floorMap['dimensions'] as List<dynamic>?;
      if (dims != null) {
        roomDimensions = RoomDimensions.fromList(dims);
      }
    }

    return RoomPlanResult(
      success: true,
      message: 'Scan completed successfully',
      captureDate: DateTime.now().toIso8601String(),
      status: 'completed',
      walls: (json['walls'] as List<dynamic>? ?? [])
          .map((wall) => WallMeasurement.fromJson(wall as Map<String, dynamic>))
          .toList(),
      objects: (json['objects'] as List<dynamic>? ?? [])
          .map((obj) => ObjectMeasurement.fromJson(obj as Map<String, dynamic>))
          .toList(),
      doors: (json['openings'] as List<dynamic>? ?? [])
          .map(
            (door) =>
                DoorWindowMeasurement.fromJson(door as Map<String, dynamic>),
          )
          .toList(),
      windows: (json['windows'] as List<dynamic>? ?? [])
          .map(
            (window) =>
                DoorWindowMeasurement.fromJson(window as Map<String, dynamic>),
          )
          .toList(),
      roomDimensions: roomDimensions,
      metadataInternal: json['metadata_internal'] as Map<String, dynamic>?,
      confidenceInternal: json['confidence_internal'] as Map<String, dynamic>?,
    );
  }

  factory RoomPlanResult.error(String message) {
    return RoomPlanResult(
      success: false,
      message: message,
      captureDate: DateTime.now().toIso8601String(),
      status: 'error',
      walls: [],
      objects: [],
      doors: [],
      windows: [],
      roomDimensions: null,
      metadataInternal: null,
      confidenceInternal: null,
    );
  }

  bool get hasMeasurements =>
      walls.isNotEmpty ||
      objects.isNotEmpty ||
      doors.isNotEmpty ||
      windows.isNotEmpty;

  int get totalItems =>
      walls.length + objects.length + doors.length + windows.length;

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'captureDate': captureDate,
      'status': status,
      'walls': walls.map((w) => w.toJson()).toList(),
      'objects': objects.map((o) => o.toJson()).toList(),
      'doors': doors.map((d) => d.toJson()).toList(),
      'windows': windows.map((w) => w.toJson()).toList(),
      'roomDimensions': roomDimensions?.toJson(),
      'metadataInternal': metadataInternal,
      'confidenceInternal': confidenceInternal,
    };
  }
}
