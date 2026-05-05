import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

void main() {
  group('Unit Conversion Tests', () {
    group('UnitConverter', () {
      test('meters to feet conversion', () {
        expect(UnitConverter.metersToFeetConversion(1.0), closeTo(3.28084, 0.0001));
        expect(UnitConverter.metersToFeetConversion(0.0), equals(0.0));
        expect(UnitConverter.metersToFeetConversion(10.0), closeTo(32.8084, 0.001));
      });

      test('feet to meters conversion', () {
        expect(UnitConverter.feetToMetersConversion(1.0), closeTo(0.3048, 0.0001));
        expect(UnitConverter.feetToMetersConversion(0.0), equals(0.0));
        expect(UnitConverter.feetToMetersConversion(10.0), closeTo(3.048, 0.001));
      });

      test('square meters to square feet conversion', () {
        expect(UnitConverter.sqMetersToSqFeetConversion(1.0), closeTo(10.7639, 0.001));
        expect(UnitConverter.sqMetersToSqFeetConversion(0.0), equals(0.0));
        expect(UnitConverter.sqMetersToSqFeetConversion(100.0), closeTo(1076.39, 0.1));
      });

      test('cubic meters to cubic feet conversion', () {
        expect(UnitConverter.cuMetersToCuFeetConversion(1.0), closeTo(35.3147, 0.001));
        expect(UnitConverter.cuMetersToCuFeetConversion(0.0), equals(0.0));
      });

      test('formatted length display', () {
        expect(UnitConverter.formatLength(1.0, MeasurementUnit.metric), equals('1.00m'));
        expect(UnitConverter.formatLength(1.0, MeasurementUnit.imperial), equals('3.28ft'));
        expect(UnitConverter.formatLength(3.048, MeasurementUnit.imperial, decimals: 0), equals('10ft'));
      });

      test('formatted area display', () {
        expect(UnitConverter.formatArea(1.0, MeasurementUnit.metric), equals('1.00m²'));
        expect(UnitConverter.formatArea(1.0, MeasurementUnit.imperial), equals('10.76sq ft'));
      });

      test('formatted volume display', () {
        expect(UnitConverter.formatVolume(1.0, MeasurementUnit.metric), equals('1.00m³'));
        expect(UnitConverter.formatVolume(1.0, MeasurementUnit.imperial), equals('35.31cu ft'));
      });
    });

    group('RoomDimensions with Units', () {
      late RoomDimensions dimensions;

      setUp(() {
        // 5m x 4m x 3m room
        dimensions = const RoomDimensions(length: 5.0, width: 4.0, height: 3.0);
      });

      test('metric values are correct', () {
        expect(dimensions.length, equals(5.0));
        expect(dimensions.width, equals(4.0));
        expect(dimensions.height, equals(3.0));
        expect(dimensions.floorArea, equals(20.0));
        expect(dimensions.volume, equals(60.0));
        expect(dimensions.perimeter, equals(18.0));
      });

      test('imperial conversions are correct', () {
        expect(dimensions.lengthInFeet, closeTo(16.404, 0.001));
        expect(dimensions.widthInFeet, closeTo(13.123, 0.001));
        expect(dimensions.heightInFeet, closeTo(9.842, 0.001));
        expect(dimensions.floorAreaInSqFeet, closeTo(215.278, 0.1));
        expect(dimensions.volumeInCuFeet, closeTo(2118.882, 0.1));
      });

      test('formatted metric display', () {
        expect(dimensions.getFormattedLength(MeasurementUnit.metric), equals('5.00m'));
        expect(dimensions.getFormattedWidth(MeasurementUnit.metric), equals('4.00m'));
        expect(dimensions.getFormattedHeight(MeasurementUnit.metric), equals('3.00m'));
        expect(dimensions.getFormattedFloorArea(MeasurementUnit.metric), equals('20.00m²'));
        expect(dimensions.getFormattedVolume(MeasurementUnit.metric), equals('60.00m³'));
      });

      test('formatted imperial display', () {
        expect(dimensions.getFormattedLength(MeasurementUnit.imperial), equals('16.40ft'));
        expect(dimensions.getFormattedWidth(MeasurementUnit.imperial), equals('13.12ft'));
        expect(dimensions.getFormattedHeight(MeasurementUnit.imperial), equals('9.84ft'));
        expect(dimensions.getFormattedFloorArea(MeasurementUnit.imperial), equals('215.28sq ft'));
        expect(dimensions.getFormattedVolume(MeasurementUnit.imperial), equals('2118.88cu ft'));
      });

      test('toString with different units', () {
        final metricStr = dimensions.toStringWithUnit(MeasurementUnit.metric);
        final imperialStr = dimensions.toStringWithUnit(MeasurementUnit.imperial);
        
        expect(metricStr, contains('5.00m'));
        expect(metricStr, contains('4.00m'));
        expect(metricStr, contains('3.00m'));
        
        expect(imperialStr, contains('16.40ft'));
        expect(imperialStr, contains('13.12ft'));
        expect(imperialStr, contains('9.84ft'));
      });

      test('JSON serialization preserves metric values', () {
        final json = dimensions.toJson();
        final restored = RoomDimensions.fromJson(json);
        
        expect(restored.length, equals(dimensions.length));
        expect(restored.width, equals(dimensions.width));
        expect(restored.height, equals(dimensions.height));
      });
    });

    group('MeasurementUnit enum', () {
      test('display names are correct', () {
        expect(MeasurementUnit.metric.displayName, equals('Metric'));
        expect(MeasurementUnit.imperial.displayName, equals('Imperial'));
      });

      test('unit symbols are correct', () {
        expect(MeasurementUnit.metric.lengthUnit, equals('m'));
        expect(MeasurementUnit.metric.areaUnit, equals('m²'));
        expect(MeasurementUnit.metric.volumeUnit, equals('m³'));
        
        expect(MeasurementUnit.imperial.lengthUnit, equals('ft'));
        expect(MeasurementUnit.imperial.areaUnit, equals('sq ft'));
        expect(MeasurementUnit.imperial.volumeUnit, equals('cu ft'));
      });
    });
  });
}