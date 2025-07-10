import 'dart:convert';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';

ScanResult? parseScanResult(String? jsonResult) {
  if (jsonResult == null) return null;
  try {
    final Map<String, dynamic> data = json.decode(jsonResult);
    return _toScanResult(data);
  } catch (e) {
    return null;
  }
}

ScanResult _toScanResult(Map<String, dynamic> data) {
  return ScanResult(
    room: _toRoomData(data),
    metadata: _toScanMetadata(data['metadata']),
    confidence: _toScanConfidence(data['confidence']),
  );
}

RoomData _toRoomData(Map<String, dynamic> data) {
  return RoomData(
    dimensions: _toRoomDimensions(data['dimensions']),
    walls: (data['walls'] as List? ?? []).map((w) => _toWallData(w)).toList(),
    objects:
        (data['objects'] as List? ?? []).map((o) => _toObjectData(o)).toList(),
    doors: (data['doors'] as List? ?? [])
        .map((d) => _toOpeningData(d, OpeningType.door))
        .toList(),
    windows: (data['windows'] as List? ?? [])
        .map((w) => _toOpeningData(w, OpeningType.window))
        .toList(),
  );
}

RoomDimensions? _toRoomDimensions(Map<String, dynamic>? data) {
  if (data == null) return null;
  return RoomDimensions(
    length: (data['x'] as num? ?? 0.0).toDouble(),
    width: (data['y'] as num? ?? 0.0).toDouble(),
    height: (data['z'] as num? ?? 0.0).toDouble(),
  );
}

WallData _toWallData(Map<String, dynamic> data) {
  return WallData(
    uuid: data['uuid'] ?? '',
    width: 0,
    height: 0,
    position: Position(Vector3.zero()),
    points: const [],
    confidence: Confidence.low,
    openings: const [],
  );
}

ObjectData _toObjectData(Map<String, dynamic> data) {
  return ObjectData(
    uuid: data['uuid'] ?? '',
    category: ObjectCategory.unknown,
    width: 0,
    height: 0,
    length: 0,
    position: Position(Vector3.zero()),
    confidence: Confidence.low,
  );
}

OpeningData _toOpeningData(Map<String, dynamic> data, OpeningType type) {
  return OpeningData(
    uuid: data['uuid'] ?? '',
    type: type,
    width: 0,
    height: 0,
    position: Position(Vector3.zero()),
    confidence: Confidence.low,
  );
}

ScanMetadata _toScanMetadata(Map<String, dynamic>? data) {
  if (data == null) {
    return ScanMetadata(
      scanDate: DateTime.now(),
      scanDuration: Duration.zero,
      deviceModel: 'Unknown',
      hasLidar: false,
    );
  }
  return ScanMetadata(
    scanDate: DateTime.now(), // Placeholder
    scanDuration: Duration(
      seconds: (data['session_duration'] as num? ?? 0).toInt(),
    ),
    deviceModel: '', // Placeholder
    hasLidar: false, // Placeholder
  );
}

ScanConfidence _toScanConfidence(Map<String, dynamic>? data) {
  if (data == null) {
    return const ScanConfidence(
      overall: 0,
      wallAccuracy: 0,
      dimensionAccuracy: 0,
    );
  }
  return ScanConfidence(
    overall: (data['overall'] as num? ?? 0.0).toDouble(),
    wallAccuracy: 0, // Placeholder
    dimensionAccuracy: 0, // Placeholder
  );
}
