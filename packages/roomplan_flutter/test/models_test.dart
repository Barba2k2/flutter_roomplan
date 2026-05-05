import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Data Model Tests', () {
    test('RoomDimensions creates valid instance', () {
      const dimensions = RoomDimensions(length: 5.0, width: 4.0, height: 2.5);
      
      expect(dimensions.length, equals(5.0));
      expect(dimensions.width, equals(4.0));
      expect(dimensions.height, equals(2.5));
    });

    test('Position creates valid instance', () {
      final position = Position(Vector3(1.0, 2.0, 3.0));
      
      expect(position.x, equals(1.0));
      expect(position.y, equals(2.0));
      expect(position.z, equals(3.0));
    });

    test('Confidence enum has all values', () {
      expect(Confidence.values.length, equals(3));
      expect(Confidence.values, contains(Confidence.low));
      expect(Confidence.values, contains(Confidence.medium));
      expect(Confidence.values, contains(Confidence.high));
    });

    test('ScanConfidence creates valid instance', () {
      const confidence = ScanConfidence(
        overall: 0.8,
        wallAccuracy: 0.9,
        dimensionAccuracy: 0.7,
      );
      
      expect(confidence.overall, equals(0.8));
      expect(confidence.wallAccuracy, equals(0.9));
      expect(confidence.dimensionAccuracy, equals(0.7));
    });
  });

  group('Exception Tests', () {
    test('RoomPlanPermissionsException has correct message', () {
      final exception = RoomPlanPermissionsException();
      expect(exception.toString(), contains('Camera permission'));
    });

    test('ScanCancelledException has correct message', () {
      final exception = ScanCancelledException();
      expect(exception.toString(), contains('cancelled'));
    });
  });
}