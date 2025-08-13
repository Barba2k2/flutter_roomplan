import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/src/mapper.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

void main() {
  group('Mapper Tests', () {
    test('parseScanResult successfully parses valid JSON', () {
      const json = '''
      {
        "dimensions": {"x": 5.0, "y": 4.0, "z": 2.5},
        "walls": [], "objects": [], "doors": [], "windows": [],
        "metadata": { "session_duration": 120 },
        "confidence": { "overall": 0.8 }
      }
      ''';

      final result = parseScanResult(json);

      expect(result, isNotNull);
      expect(result, isA<ScanResult>());
      expect(result?.room.dimensions?.length, 5.0);
      expect(result?.room.dimensions?.width, 4.0);
      expect(result?.room.dimensions?.height, 2.5);
      expect(result?.metadata.scanDuration, const Duration(seconds: 120));
      expect(result?.confidence.overall, 0.8);
    });

    test('parseScanResult returns null for invalid JSON', () {
      const json = 'this is not json';
      final result = parseScanResult(json);
      expect(result, isNull);
    });

    test('parseScanResult returns a default object for incomplete JSON', () {
      const json = '{"walls": []}';
      final result = parseScanResult(json);
      expect(result, isNotNull);
      expect(result, isA<ScanResult>());
      expect(result?.room.walls, isEmpty);
      expect(result?.confidence.overall, equals(0.0));
    });

    test('parseScanResult returns null for null input', () {
      final result = parseScanResult(null);
      expect(result, isNull);
    });
  });
}
