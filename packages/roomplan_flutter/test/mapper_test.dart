import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/src/performance/optimized_mapper.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

void main() {
  group('Mapper Tests', () {
    test('parseScanResult successfully parses valid JSON', () {
      const json = '''
      {
        "dimensions": {"x": 5.0, "y": 2.5, "z": 4.0},
        "walls": [], "objects": [], "windows": [],
        "doors": [{"uuid": "d", "confidence": "high", "dimensions": {"x": 0.9, "y": 2.0, "z": 0.0}}],
        "metadata": { "session_duration": 120 }
      }
      ''';

      final result = OptimizedMapper.parseScanResult(json);

      expect(result, isNotNull);
      expect(result, isA<ScanResult>());
      expect(result?.room.dimensions?.length, 5.0);
      expect(result?.room.dimensions?.width, 4.0);
      expect(result?.room.dimensions?.height, 2.5);
      expect(result?.metadata.scanDuration, const Duration(seconds: 120));
      expect(result?.confidence.overall, 1.0);
    });

    test('walls, doors and windows use surface axes (x=width, y=height)', () {
      const json = '''
      {
        "walls": [{"uuid": "w", "dimensions": {"x": 4.0, "y": 2.5, "z": 0.0}}],
        "doors": [{"uuid": "d", "dimensions": {"x": 0.9, "y": 2.0, "z": 0.0}}],
        "windows": [{"uuid": "n", "dimensions": {"x": 1.2, "y": 1.0, "z": 0.1}}]
      }
      ''';

      final room = OptimizedMapper.parseScanResult(json)!.room;
      expect(room.walls.first.width, 4.0);
      expect(room.walls.first.height, 2.5);
      expect(room.doors.first.width, 0.9);
      expect(room.doors.first.height, 2.0);
      expect(room.windows.first.width, 1.2);
      expect(room.windows.first.height, 1.0);
    });

    test('parseScanResult returns null for invalid JSON', () {
      const json = 'this is not json';
      final result = OptimizedMapper.parseScanResult(json);
      expect(result, isNull);
    });

    test('parseScanResult returns a default object for incomplete JSON', () {
      const json = '{"walls": []}';
      final result = OptimizedMapper.parseScanResult(json);
      expect(result, isNotNull);
      expect(result, isA<ScanResult>());
      expect(result?.room.walls, isEmpty);
      expect(result?.confidence.overall, equals(0.0));
    });

    test('parseScanResult returns null for null input', () {
      final result = OptimizedMapper.parseScanResult(null);
      expect(result, isNull);
    });
  });
}
