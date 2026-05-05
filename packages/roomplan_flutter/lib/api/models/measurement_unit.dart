/// Enumeration for measurement unit systems.
enum MeasurementUnit {
  /// Metric system (meters, square meters, cubic meters)
  metric,
  
  /// Imperial/US system (feet, square feet, cubic feet)
  imperial;
  
  /// Returns the display name for the unit system.
  String get displayName {
    switch (this) {
      case MeasurementUnit.metric:
        return 'Metric';
      case MeasurementUnit.imperial:
        return 'Imperial';
    }
  }
  
  /// Returns the length unit symbol.
  String get lengthUnit {
    switch (this) {
      case MeasurementUnit.metric:
        return 'm';
      case MeasurementUnit.imperial:
        return 'ft';
    }
  }
  
  /// Returns the area unit symbol.
  String get areaUnit {
    switch (this) {
      case MeasurementUnit.metric:
        return 'm²';
      case MeasurementUnit.imperial:
        return 'sq ft';
    }
  }
  
  /// Returns the volume unit symbol.
  String get volumeUnit {
    switch (this) {
      case MeasurementUnit.metric:
        return 'm³';
      case MeasurementUnit.imperial:
        return 'cu ft';
    }
  }
}

/// Utility class for unit conversions between metric and imperial systems.
class UnitConverter {
  /// Conversion factor from meters to feet.
  static const double metersToFeet = 3.28084;
  
  /// Conversion factor from feet to meters.
  static const double feetToMeters = 0.3048;
  
  /// Conversion factor from square meters to square feet.
  static const double sqMetersToSqFeet = 10.7639;
  
  /// Conversion factor from square feet to square meters.
  static const double sqFeetToSqMeters = 0.092903;
  
  /// Conversion factor from cubic meters to cubic feet.
  static const double cuMetersToFeet = 35.3147;
  
  /// Conversion factor from cubic feet to cubic meters.
  static const double cuFeetToMeters = 0.0283168;
  
  /// Converts meters to feet.
  static double metersToFeetConversion(double meters) {
    return meters * metersToFeet;
  }
  
  /// Converts feet to meters.
  static double feetToMetersConversion(double feet) {
    return feet * feetToMeters;
  }
  
  /// Converts square meters to square feet.
  static double sqMetersToSqFeetConversion(double sqMeters) {
    return sqMeters * sqMetersToSqFeet;
  }
  
  /// Converts square feet to square meters.
  static double sqFeetToSqMetersConversion(double sqFeet) {
    return sqFeet * sqFeetToSqMeters;
  }
  
  /// Converts cubic meters to cubic feet.
  static double cuMetersToCuFeetConversion(double cuMeters) {
    return cuMeters * cuMetersToFeet;
  }
  
  /// Converts cubic feet to cubic meters.
  static double cuFeetToCuMetersConversion(double cuFeet) {
    return cuFeet * cuFeetToMeters;
  }
  
  /// Formats a length value with appropriate unit and precision.
  static String formatLength(double meters, MeasurementUnit unit, {int decimals = 2}) {
    switch (unit) {
      case MeasurementUnit.metric:
        return '${meters.toStringAsFixed(decimals)}${unit.lengthUnit}';
      case MeasurementUnit.imperial:
        final feet = metersToFeetConversion(meters);
        return '${feet.toStringAsFixed(decimals)}${unit.lengthUnit}';
    }
  }
  
  /// Formats an area value with appropriate unit and precision.
  static String formatArea(double sqMeters, MeasurementUnit unit, {int decimals = 2}) {
    switch (unit) {
      case MeasurementUnit.metric:
        return '${sqMeters.toStringAsFixed(decimals)}${unit.areaUnit}';
      case MeasurementUnit.imperial:
        final sqFeet = sqMetersToSqFeetConversion(sqMeters);
        return '${sqFeet.toStringAsFixed(decimals)}${unit.areaUnit}';
    }
  }
  
  /// Formats a volume value with appropriate unit and precision.
  static String formatVolume(double cuMeters, MeasurementUnit unit, {int decimals = 2}) {
    switch (unit) {
      case MeasurementUnit.metric:
        return '${cuMeters.toStringAsFixed(decimals)}${unit.volumeUnit}';
      case MeasurementUnit.imperial:
        final cuFeet = cuMetersToCuFeetConversion(cuMeters);
        return '${cuFeet.toStringAsFixed(decimals)}${unit.volumeUnit}';
    }
  }
}