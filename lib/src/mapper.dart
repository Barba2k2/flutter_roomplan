import 'dart:convert';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:roomplan_flutter/src/models/door_window_measurement.dart'
    as internal;
import 'package:roomplan_flutter/src/models/object_measurement.dart'
    as internal;
import 'package:roomplan_flutter/src/models/room_plan_result.dart' as internal;
import 'package:roomplan_flutter/src/models/wall_measurement.dart' as internal;
import 'package:vector_math/vector_math_64.dart';

/// Parses the raw JSON string from the native side into a [ScanResult] object.
///
/// Returns `null` if parsing fails.
ScanResult? parseScanResult(String? jsonResult) {
  if (jsonResult == null) return null;
  try {
    final roomPlanResult = internal.RoomPlanResult.fromJson(
      json.decode(jsonResult),
    );
    return _toScanResult(roomPlanResult);
  } catch (e) {
    // ignore: avoid_print
    print('Error parsing scan result: $e');
    return null;
  }
}

/// Converts the internal [internal.RoomPlanResult] to the public [ScanResult].
ScanResult? _toScanResult(internal.RoomPlanResult internalResult) {
  try {
    final roomData = _toRoomData(internalResult);
    if (roomData == null) return null;

    final metadata = _toScanMetadata(internalResult.metadataInternal);
    final confidence = _toScanConfidence(internalResult.confidenceInternal);

    return ScanResult(
      room: roomData,
      metadata: metadata,
      confidence: confidence,
    );
  } catch (e) {
    // ignore: avoid_print
    print('Error converting internal result to ScanResult: $e');
    return null;
  }
}

/// Converts the internal [internal.RoomPlanResult] to the public [RoomData].
RoomData? _toRoomData(internal.RoomPlanResult internalResult) {
  final walls =
      internalResult.walls.map<WallData>((w) => _toWallData(w)).toList();
  final objects =
      internalResult.objects.map<ObjectData>((o) => _toObjectData(o)).toList();
  final doors =
      internalResult.doors.map<OpeningData>((d) => _toOpeningData(d)).toList();
  final windows = internalResult.windows
      .map<OpeningData>((w) => _toOpeningData(w))
      .toList();

  return RoomData(
    dimensions: internalResult.roomDimensions != null
        ? RoomDimensions(
            width: internalResult.roomDimensions!.width,
            height: internalResult.roomDimensions!.height,
            length: internalResult.roomDimensions!.depth,
          )
        : null,
    walls: walls,
    objects: objects,
    doors: doors,
    windows: windows,
  );
}

/// Converts the internal [internal.ObjectMeasurement] to the public [ObjectData].
ObjectData _toObjectData(internal.ObjectMeasurement internalObject) {
  return ObjectData(
    uuid: internalObject.id,
    position: Position(
      Vector3(
        internalObject.position['x'] ?? 0,
        internalObject.position['y'] ?? 0,
        internalObject.position['z'] ?? 0,
      ),
    ),
    category: _toObjectCategory(internalObject.category),
    width: internalObject.dimensions.width,
    height: internalObject.dimensions.height,
    length: internalObject.dimensions.depth,
    confidence: _toConfidenceFromString(internalObject.confidence),
  );
}

/// Converts the internal category string to the public [ObjectCategory] enum.
ObjectCategory _toObjectCategory(String internal) {
  return ObjectCategory.values.firstWhere(
    (e) => e.name.toLowerCase() == internal.toLowerCase(),
    orElse: () => ObjectCategory.unknown,
  );
}

/// Converts the internal [internal.WallMeasurement] to the public [WallData].
WallData _toWallData(internal.WallMeasurement internalWall) {
  return WallData(
    uuid: internalWall.id,
    position: Position(
      Vector3(
        internalWall.position['x'] ?? 0,
        internalWall.position['y'] ?? 0,
        internalWall.position['z'] ?? 0,
      ),
    ),
    points: const [], // The internal model does not provide wall vertices.
    width: internalWall.dimensions.width,
    height: internalWall.dimensions.height,
    confidence: _toConfidenceFromString(internalWall.confidence),
    openings: const [], // Openings are not associated with walls in this model.
  );
}

/// Converts the internal opening data to the public [OpeningData].
OpeningData _toOpeningData(internal.DoorWindowMeasurement internalOpening) {
  return OpeningData(
    uuid: internalOpening.id,
    type: internalOpening.category == 'door'
        ? OpeningType.door
        : OpeningType.window,
    position: Position(
      Vector3(
        internalOpening.position['x'] ?? 0,
        internalOpening.position['y'] ?? 0,
        internalOpening.position['z'] ?? 0,
      ),
    ),
    width: internalOpening.dimensions.width,
    height: internalOpening.dimensions.height,
    confidence: _toConfidenceFromString(internalOpening.confidence),
  );
}

/// Converts the internal confidence string to the public [Confidence] enum.
Confidence _toConfidenceFromString(String internal) {
  return Confidence.values.firstWhere(
    (e) => e.name.toLowerCase() == internal.toLowerCase(),
    orElse: () => Confidence.low,
  );
}

/// Converts the internal metadata map to the public [ScanMetadata] object.
ScanMetadata _toScanMetadata(Map<String, dynamic>? internal) {
  if (internal == null) {
    return ScanMetadata(
      scanDate: DateTime.now(),
      scanDuration: Duration.zero,
      deviceModel: 'Unknown',
      hasLidar: false,
    );
  }
  return ScanMetadata(
    scanDate: DateTime.tryParse(internal['scanDate'] ?? '') ?? DateTime.now(),
    scanDuration:
        Duration(seconds: (internal['scanDuration'] as num? ?? 0).toInt()),
    deviceModel: internal['deviceModel'] as String? ?? 'Unknown',
    hasLidar: internal['hasLidar'] as bool? ?? false,
  );
}

/// Converts the internal confidence map to the public [ScanConfidence] object.
ScanConfidence _toScanConfidence(Map<String, dynamic>? internal) {
  if (internal == null) {
    return const ScanConfidence(
      overall: 0.0,
      wallAccuracy: 0.0,
      dimensionAccuracy: 0.0,
    );
  }
  return ScanConfidence(
    overall: (internal['overall'] as num? ?? 0.0).toDouble(),
    wallAccuracy: (internal['wallAccuracy'] as num? ?? 0.0).toDouble(),
    dimensionAccuracy:
        (internal['dimensionAccuracy'] as num? ?? 0.0).toDouble(),
    warnings: const [], // Warnings are not supported yet.
  );
}
