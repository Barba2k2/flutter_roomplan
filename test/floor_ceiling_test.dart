import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/src/mapper.dart';

void main() {
  group('Floor and Ceiling parsing', () {
    test('Both floor and ceiling detected', () {
      final jsonMap = {
        'room': {
          'walls': [],
          'objects': [],
          'doors': [],
          'windows': [],
          'openings': [],
          'floor': {
            'uuid': 'f',
            'dimensions': {'x': 5.0, 'y': 4.0, 'z': 0.0},
            'transform': List<double>.filled(16, 0)
              ..[0] = 1
              ..[5] = 1
              ..[10] = 1
              ..[15] = 1,
            'confidence': 'high',
          },
          'ceiling': {
            'uuid': 'c',
            'dimensions': {'x': 5.0, 'y': 4.0, 'z': 0.0},
            'transform': List<double>.filled(16, 0)
              ..[0] = 1
              ..[5] = 1
              ..[10] = 1
              ..[15] = 1,
            'confidence': 'medium',
          },
        }
      };

      final result = parseScanResult(json.encode(jsonMap));
      expect(result, isNotNull);
      expect(result!.room.floor, isNotNull);
      expect(result.room.ceiling, isNotNull);
      expect(result.room.floor!.dimensions!.length, 5.0);
      expect(result.room.floor!.dimensions!.width, 4.0);
      expect(result.room.floor!.dimensions!.floorArea, 20.0);
    });

    test('Missing floor and ceiling handled', () {
      final jsonMap = {
        'room': {
          'walls': [],
          'objects': [],
          'doors': [],
          'windows': [],
          'openings': [],
        }
      };

      final result = parseScanResult(json.encode(jsonMap));
      expect(result, isNotNull);
      expect(result!.room.floor, isNull);
      expect(result.room.ceiling, isNull);
    });
  });
}
