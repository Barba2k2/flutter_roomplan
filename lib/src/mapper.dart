import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';

ScanResult? parseScanResult(String? jsonResult) {
  if (jsonResult == null) return null;
  try {
    final Map<String, dynamic> data = json.decode(jsonResult);
    return _toScanResult(data);
  } catch (e, stacktrace) {
    debugPrint('Error parsing scan result: $e');
    debugPrint(stacktrace.toString());
    return null;
  }
}

ScanResult _toScanResult(Map<String, dynamic> data) {
  return ScanResult(
    room: _toRoomData(data['room'] as Map<String, dynamic>),
    metadata: _toScanMetadata(data['metadata'] as Map<String, dynamic>?),
    confidence: _toScanConfidence(data['room'] as Map<String, dynamic>?),
  );
}

RoomData _toRoomData(Map<String, dynamic> data) {
  final floor = data['floor'] != null
      ? _toWallData(data['floor'] as Map<String, dynamic>)
      : null;
  final ceiling = data['ceiling'] != null
      ? _toWallData(data['ceiling'] as Map<String, dynamic>)
      : null;

  return RoomData(
    dimensions: floor?.dimensions,
    walls: (data['walls'] as List? ?? [])
        .map((w) => _toWallData(w as Map<String, dynamic>))
        .toList(),
    objects: (data['objects'] as List? ?? [])
        .map((o) => _toObjectData(o as Map<String, dynamic>))
        .toList(),
    doors: (data['doors'] as List? ?? [])
        .map((d) => _toOpeningData(d as Map<String, dynamic>, OpeningType.door))
        .toList(),
    windows: (data['windows'] as List? ?? [])
        .map((w) =>
            _toOpeningData(w as Map<String, dynamic>, OpeningType.window))
        .toList(),
    openings: (data['openings'] as List? ?? [])
        .map((o) =>
            _toOpeningData(o as Map<String, dynamic>, OpeningType.opening))
        .toList(),
    floor: floor,
    ceiling: ceiling,
  );
}

RoomDimensions? _toRoomDimensions(Map<String, dynamic>? data) {
  if (data == null) return null;
  return RoomDimensions(
    length: (data['z'] as num? ?? 0.0).toDouble(),
    width: (data['x'] as num? ?? 0.0).toDouble(),
    height: (data['y'] as num? ?? 0.0).toDouble(),
  );
}

Matrix4? _toMatrix(List<dynamic>? data) {
  if (data == null) return null;
  // The native side sends a row-major matrix, but Matrix4.fromList expects
  // a column-major matrix, so we need to transpose it.
  final list = data.cast<num>().map((e) => e.toDouble()).toList();
  return Matrix4.fromList(list);
}

WallData _toWallData(Map<String, dynamic> data) {
  final dimensions =
      _toRoomDimensions(data['dimensions'] as Map<String, dynamic>?);
  final transform = _toMatrix(data['transform'] as List<dynamic>?);
  final position = transform != null
      ? Position(transform.getTranslation())
      : Position(Vector3.zero());

  final doorsList = data['doors'] as List? ?? [];
  final windowsList = data['windows'] as List? ?? [];

  final doors = doorsList
      .map((d) => _toOpeningData(d as Map<String, dynamic>, OpeningType.door))
      .toList();
  final windows = windowsList
      .map((w) => _toOpeningData(w as Map<String, dynamic>, OpeningType.window))
      .toList();

  return WallData(
    uuid: data['uuid'] as String? ?? '',
    width: dimensions?.width ?? 0,
    height: dimensions?.height ?? 0,
    position: position,
    points: const [],
    confidence: _toConfidence(data['confidence'] as String?),
    openings: [...doors, ...windows],
    dimensions: dimensions,
    transform: transform,
  );
}

ObjectData _toObjectData(Map<String, dynamic> data) {
  final dimensions =
      _toRoomDimensions(data['dimensions'] as Map<String, dynamic>?);
  final transform = _toMatrix(data['transform'] as List<dynamic>?);
  final position = transform != null
      ? Position(transform.getTranslation())
      : Position(Vector3.zero());
  return ObjectData(
    uuid: data['uuid'] as String? ?? '',
    category: _toObjectCategory(data['category'] as String?),
    width: dimensions?.width ?? 0,
    height: dimensions?.height ?? 0,
    length: dimensions?.length ?? 0,
    position: position,
    confidence: _toConfidence(data['confidence'] as String?),
    dimensions: dimensions,
    transform: transform,
  );
}

OpeningData _toOpeningData(Map<String, dynamic> data, OpeningType type) {
  final dimensions =
      _toRoomDimensions(data['dimensions'] as Map<String, dynamic>?);
  final transform = _toMatrix(data['transform'] as List<dynamic>?);
  final position = transform != null
      ? Position(transform.getTranslation())
      : Position(Vector3.zero());

  return OpeningData(
    uuid: data['uuid'] as String? ?? '',
    type: type,
    width: dimensions?.width ?? 0,
    height: dimensions?.height ?? 0,
    position: position,
    confidence: _toConfidence(data['confidence'] as String?),
    dimensions: dimensions,
    transform: transform,
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

  // Parse duration from a double representing seconds
  final durationInSeconds =
      double.tryParse(data['session_duration'] ?? '0.0') ?? 0.0;
  final scanDuration =
      Duration(microseconds: (durationInSeconds * 1000000).round());

  // Parse hasLidar from a string
  final hasLidar = (data['has_lidar'] as String? ?? 'false') == 'true';

  return ScanMetadata(
    scanDate: DateTime.now(), // Scan date is not provided from native side yet
    scanDuration: scanDuration,
    deviceModel: data['device_model'] as String? ?? 'Unknown',
    hasLidar: hasLidar,
  );
}

ScanConfidence _toScanConfidence(Map<String, dynamic>? roomData) {
  if (roomData == null) {
    return const ScanConfidence(
      overall: 0,
      wallAccuracy: 0,
      dimensionAccuracy: 0,
    );
  }

  double confidenceToDouble(String? confidence) {
    switch (confidence) {
      case 'low':
        return 0.33;
      case 'medium':
        return 0.66;
      case 'high':
        return 1.0;
      default:
        return 0.0;
    }
  }

  final walls = roomData['walls'] as List? ?? [];
  final objects = roomData['objects'] as List? ?? [];
  final doors = roomData['doors'] as List? ?? [];
  final windows = roomData['windows'] as List? ?? [];
  final openings = roomData['openings'] as List? ?? [];

  final allItems = [...walls, ...objects, ...doors, ...windows, ...openings];

  double wallConfidenceSum = 0;
  if (walls.isNotEmpty) {
    for (final wall in walls) {
      wallConfidenceSum += confidenceToDouble(wall['confidence'] as String?);
    }
  }
  final wallAccuracy =
      walls.isNotEmpty ? wallConfidenceSum / walls.length : 0.0;

  double objectConfidenceSum = 0;
  if (objects.isNotEmpty) {
    for (final object in objects) {
      objectConfidenceSum +=
          confidenceToDouble(object['confidence'] as String?);
    }
  }
  final dimensionAccuracy =
      objects.isNotEmpty ? objectConfidenceSum / objects.length : 0.0;

  double totalConfidenceSum = 0;
  if (allItems.isNotEmpty) {
    for (final item in allItems) {
      totalConfidenceSum += confidenceToDouble(item['confidence'] as String?);
    }
  }
  final overallAccuracy =
      allItems.isNotEmpty ? totalConfidenceSum / allItems.length : 0.0;

  return ScanConfidence(
    overall: overallAccuracy,
    wallAccuracy: wallAccuracy,
    dimensionAccuracy: dimensionAccuracy,
  );
}

Confidence _toConfidence(String? confidence) {
  switch (confidence) {
    case 'low':
      return Confidence.low;
    case 'medium':
      return Confidence.medium;
    case 'high':
      return Confidence.high;
    default:
      return Confidence.low;
  }
}

ObjectCategory _toObjectCategory(String? category) {
  for (final value in ObjectCategory.values) {
    if (value.name == category) {
      return value;
    }
  }
  return ObjectCategory.unknown;
}
