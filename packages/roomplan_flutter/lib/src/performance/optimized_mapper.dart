import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';
import 'object_pool.dart';
import 'performance_monitor.dart';

/// Performance-optimized JSON parser with caching and object pooling
class OptimizedMapper {
  // Performance optimization: Cache for repeated category calculations
  static final Map<String, ObjectCategory> _categoryCache = {};

  // Performance optimization: Pre-compiled confidence mapping
  static const Map<String, double> _confidenceMap = {
    'low': 0.33,
    'medium': 0.66,
    'high': 1.0,
  };

  /// Parse scan result with performance optimizations
  static ScanResult? parseScanResult(String? jsonResult) {
    if (jsonResult == null) return null;

    return PerformanceMonitor.timeOperation('json_parse_total', () {
      try {
        final data = PerformanceMonitor.timeOperation('json_decode', () {
          return json.decode(jsonResult) as Map<String, dynamic>;
        });

        return PerformanceMonitor.timeOperation('scan_result_conversion', () {
          return _toScanResultOptimized(data);
        });
      } catch (e, stacktrace) {
        // Performance optimization: Only print debug info in debug mode
        assert(() {
          debugPrint('Error parsing scan result: $e');
          debugPrint(stacktrace.toString());
          return true;
        }());
        return null;
      }
    });
  }

  static ScanResult _toScanResultOptimized(Map<String, dynamic> data) {
    // Performance optimization: Reduce map lookups with local variables
    final roomData = data['room'] as Map<String, dynamic>? ?? data;
    final metadataData = data['metadata'] as Map<String, dynamic>?;
    final confidenceData = data['confidence'] as Map<String, dynamic>? ??
        roomData['confidence'] as Map<String, dynamic>?;

    return ScanResult(
      room: _toRoomDataOptimized(roomData),
      metadata: _toScanMetadataOptimized(metadataData),
      confidence: _toScanConfidenceOptimized(confidenceData, roomData),
    );
  }

  static RoomData _toRoomDataOptimized(Map<String, dynamic> data) {
    // Performance optimization: Single-pass list processing with type checking
    final wallsData = data['walls'] as List?;
    final objectsData = data['objects'] as List?;
    final doorsData = data['doors'] as List?;
    final windowsData = data['windows'] as List?;
    final openingsData = data['openings'] as List?;

    final walls = wallsData
            ?.map((w) => _toWallDataOptimized(w as Map<String, dynamic>))
            .toList() ??
        <WallData>[];
    final objects = objectsData
            ?.map((o) => _toObjectDataOptimized(o as Map<String, dynamic>))
            .toList() ??
        <ObjectData>[];
    final doors = doorsData
            ?.map((d) => _toOpeningDataOptimized(
                d as Map<String, dynamic>, OpeningType.door))
            .toList() ??
        <OpeningData>[];
    final windows = windowsData
            ?.map((w) => _toOpeningDataOptimized(
                w as Map<String, dynamic>, OpeningType.window))
            .toList() ??
        <OpeningData>[];
    final openings = openingsData
            ?.map((o) => _toOpeningDataOptimized(
                o as Map<String, dynamic>, OpeningType.opening))
            .toList() ??
        <OpeningData>[];

    final floor = data['floor'] != null
        ? _toWallDataOptimized(data['floor'] as Map<String, dynamic>)
        : null;
    final ceiling = data['ceiling'] != null
        ? _toWallDataOptimized(data['ceiling'] as Map<String, dynamic>)
        : null;
    final dimensions = _toRoomDimensionsOptimized(
            data['dimensions'] as Map<String, dynamic>?) ??
        floor?.dimensions;

    return RoomData(
      dimensions: dimensions,
      walls: walls,
      objects: objects,
      doors: doors,
      windows: windows,
      openings: openings,
      floor: floor,
      ceiling: ceiling,
    );
  }

  static RoomDimensions? _toRoomDimensionsOptimized(
      Map<String, dynamic>? data) {
    if (data == null) return null;

    // Performance optimization: Direct double conversion without intermediate variables
    // Fixed mapping: x=length, y=height, z=width (matching Swift simd_float3 convention)
    return RoomDimensions(
      length: (data['x'] as num? ?? 0.0).toDouble(),
      width: (data['z'] as num? ?? 0.0).toDouble(),
      height: (data['y'] as num? ?? 0.0).toDouble(),
    );
  }

  static Matrix4? _toMatrixOptimized(List<dynamic>? data) {
    if (data == null) return null;

    // Performance optimization: Direct Matrix4 creation from list
    final list = data.cast<num>().map((e) => e.toDouble()).toList();
    return Matrix4.fromList(list);
  }

  static Position _getPositionFromTransform(Matrix4? transform) {
    if (transform == null) return Position(Vector3.zero());

    // Performance optimization: Direct translation extraction
    return Position(transform.getTranslation());
  }

  static WallData _toWallDataOptimized(Map<String, dynamic> data) {
    final dimensions =
        _toRoomDimensionsOptimized(data['dimensions'] as Map<String, dynamic>?);
    final transform = _toMatrixOptimized(data['transform'] as List<dynamic>?);
    final position = _getPositionFromTransform(transform);

    // Performance optimization: Combine door and window lists efficiently
    final doorsList = data['doors'] as List? ?? <dynamic>[];
    final windowsList = data['windows'] as List? ?? <dynamic>[];

    final openings = <OpeningData>[];
    openings.addAll(doorsList.map((d) =>
        _toOpeningDataOptimized(d as Map<String, dynamic>, OpeningType.door)));
    openings.addAll(windowsList.map((w) => _toOpeningDataOptimized(
        w as Map<String, dynamic>, OpeningType.window)));

    return WallData(
      uuid: data['uuid'] as String? ?? '',
      width: dimensions?.width ?? 0,
      height: dimensions?.height ?? 0,
      position: position,
      points: const [], // Performance: Use empty const list
      confidence: _toConfidenceOptimized(data['confidence'] as String?),
      openings: openings,
      dimensions: dimensions,
      transform: transform,
    );
  }

  static ObjectData _toObjectDataOptimized(Map<String, dynamic> data) {
    final dimensions =
        _toRoomDimensionsOptimized(data['dimensions'] as Map<String, dynamic>?);
    final transform = _toMatrixOptimized(data['transform'] as List<dynamic>?);
    final position = _getPositionFromTransform(transform);

    return ObjectData(
      uuid: data['uuid'] as String? ?? '',
      category: _toObjectCategoryOptimized(data['category'] as String?),
      width: dimensions?.width ?? 0,
      height: dimensions?.height ?? 0,
      length: dimensions?.length ?? 0,
      position: position,
      confidence: _toConfidenceOptimized(data['confidence'] as String?),
      dimensions: dimensions,
      transform: transform,
    );
  }

  static OpeningData _toOpeningDataOptimized(
      Map<String, dynamic> data, OpeningType type) {
    final dimensions =
        _toRoomDimensionsOptimized(data['dimensions'] as Map<String, dynamic>?);
    final transform = _toMatrixOptimized(data['transform'] as List<dynamic>?);
    final position = _getPositionFromTransform(transform);

    return OpeningData(
      uuid: data['uuid'] as String? ?? '',
      type: type,
      width: dimensions?.width ?? 0,
      height: dimensions?.height ?? 0,
      position: position,
      confidence: _toConfidenceOptimized(data['confidence'] as String?),
      dimensions: dimensions,
      transform: transform,
    );
  }

  static ScanMetadata _toScanMetadataOptimized(Map<String, dynamic>? data) {
    if (data == null) {
      return ScanMetadata(
        scanDate: DateTime.now(),
        scanDuration: Duration.zero,
        deviceModel: 'Unknown',
        hasLidar: false,
      );
    }

    // Performance optimization: More efficient duration parsing
    final durationInSeconds = switch (data['session_duration']) {
      num value => value.toDouble(),
      String value => double.tryParse(value) ?? 0.0,
      _ => 0.0,
    };

    final scanDuration =
        Duration(microseconds: (durationInSeconds * 1000000).round());
    final hasLidar = (data['has_lidar'] as String? ?? 'false') == 'true';

    return ScanMetadata(
      scanDate: DateTime.now(),
      scanDuration: scanDuration,
      deviceModel: data['device_model'] as String? ?? 'Unknown',
      hasLidar: hasLidar,
    );
  }

  static ScanConfidence _toScanConfidenceOptimized(
      Map<String, dynamic>? confidenceData, Map<String, dynamic>? roomData) {
    if (confidenceData?.containsKey('overall') == true) {
      return ScanConfidence(
        overall: (confidenceData!['overall'] as num?)?.toDouble() ?? 0.0,
        wallAccuracy:
            (confidenceData['wallAccuracy'] as num?)?.toDouble() ?? 0.0,
        dimensionAccuracy:
            (confidenceData['dimensionAccuracy'] as num?)?.toDouble() ?? 0.0,
      );
    }

    // Performance optimization: Efficient confidence calculation with single pass
    if (roomData == null) {
      return const ScanConfidence(
          overall: 0.0, wallAccuracy: 0.0, dimensionAccuracy: 0.0);
    }

    return _calculateConfidenceFromRoomData(roomData);
  }

  static ScanConfidence _calculateConfidenceFromRoomData(
      Map<String, dynamic> roomData) {
    // Performance optimization: Single-pass calculation with early termination
    double wallSum = 0, objectSum = 0, totalSum = 0;
    int wallCount = 0, objectCount = 0, totalCount = 0;

    // Process walls
    final walls = roomData['walls'] as List? ?? <dynamic>[];
    for (final wall in walls) {
      final confidence =
          _getConfidenceValueOptimized(wall['confidence'] as String?);
      wallSum += confidence;
      totalSum += confidence;
      wallCount++;
      totalCount++;
    }

    // Process objects
    final objects = roomData['objects'] as List? ?? <dynamic>[];
    for (final object in objects) {
      final confidence =
          _getConfidenceValueOptimized(object['confidence'] as String?);
      objectSum += confidence;
      totalSum += confidence;
      objectCount++;
      totalCount++;
    }

    // Process doors, windows, openings
    for (final listKey in ['doors', 'windows', 'openings']) {
      final items = roomData[listKey] as List? ?? <dynamic>[];
      for (final item in items) {
        final confidence =
            _getConfidenceValueOptimized(item['confidence'] as String?);
        totalSum += confidence;
        totalCount++;
      }
    }

    return ScanConfidence(
      overall: totalCount > 0 ? totalSum / totalCount : 0.0,
      wallAccuracy: wallCount > 0 ? wallSum / wallCount : 0.0,
      dimensionAccuracy: objectCount > 0 ? objectSum / objectCount : 0.0,
    );
  }

  static double _getConfidenceValueOptimized(String? confidence) {
    // Performance optimization: Use pre-computed map lookup
    return _confidenceMap[confidence] ?? 0.0;
  }

  static Confidence _toConfidenceOptimized(String? confidence) {
    // Performance optimization: Direct enum lookup without caching
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

  static ObjectCategory _toObjectCategoryOptimized(String? category) {
    // Performance optimization: Cache category enum lookups
    return _categoryCache.putIfAbsent(category ?? '', () {
      for (final value in ObjectCategory.values) {
        if (value.name == category) {
          return value;
        }
      }
      return ObjectCategory.unknown;
    });
  }

  /// Clear caches (useful for testing or memory pressure)
  static void clearCaches() {
    _categoryCache.clear();
    ObjectPools.clearAll();
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'category_cache_size': _categoryCache.length,
      ...ObjectPools.getPoolStats(),
    };
  }
}
