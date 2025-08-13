import 'measurement_unit.dart';

/// Represents the dimensions of a scanned room.
class RoomDimensions {
  /// The width of the room.
  final double width;

  /// The height of the room.
  final double height;

  /// The length (depth) of the room.
  final double length;

  /// Creates a [RoomDimensions] object.
  const RoomDimensions({
    required this.width,
    required this.height,
    required this.length,
  });
  
  /// Creates a [RoomDimensions] from a JSON map.
  factory RoomDimensions.fromJson(Map<String, dynamic> json) {
    return RoomDimensions(
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  /// Converts this [RoomDimensions] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'width': width,
      'height': height,
    };
  }
  
  /// Creates a copy of this dimensions with modified values.
  RoomDimensions copyWith({
    double? length,
    double? width,
    double? height,
  }) {
    return RoomDimensions(
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
  
  /// Returns the volume of the room in cubic meters.
  double get volume => length * width * height;
  
  /// Returns the floor area in square meters.
  double get floorArea => length * width;
  
  /// Returns the perimeter in meters.
  double get perimeter => 2 * (length + width);
  
  // Imperial unit conversions
  
  /// Returns the length in feet.
  double get lengthInFeet => UnitConverter.metersToFeetConversion(length);
  
  /// Returns the width in feet.
  double get widthInFeet => UnitConverter.metersToFeetConversion(width);
  
  /// Returns the height in feet.
  double get heightInFeet => UnitConverter.metersToFeetConversion(height);
  
  /// Returns the floor area in square feet.
  double get floorAreaInSqFeet => UnitConverter.sqMetersToSqFeetConversion(floorArea);
  
  /// Returns the volume in cubic feet.
  double get volumeInCuFeet => UnitConverter.cuMetersToCuFeetConversion(volume);
  
  /// Returns the perimeter in feet.
  double get perimeterInFeet => UnitConverter.metersToFeetConversion(perimeter);
  
  // Formatted display methods
  
  /// Returns formatted length string in the specified unit.
  String getFormattedLength(MeasurementUnit unit, {int decimals = 2}) {
    return UnitConverter.formatLength(length, unit, decimals: decimals);
  }
  
  /// Returns formatted width string in the specified unit.
  String getFormattedWidth(MeasurementUnit unit, {int decimals = 2}) {
    return UnitConverter.formatLength(width, unit, decimals: decimals);
  }
  
  /// Returns formatted height string in the specified unit.
  String getFormattedHeight(MeasurementUnit unit, {int decimals = 2}) {
    return UnitConverter.formatLength(height, unit, decimals: decimals);
  }
  
  /// Returns formatted floor area string in the specified unit.
  String getFormattedFloorArea(MeasurementUnit unit, {int decimals = 2}) {
    return UnitConverter.formatArea(floorArea, unit, decimals: decimals);
  }
  
  /// Returns formatted volume string in the specified unit.
  String getFormattedVolume(MeasurementUnit unit, {int decimals = 2}) {
    return UnitConverter.formatVolume(volume, unit, decimals: decimals);
  }
  
  /// Returns formatted perimeter string in the specified unit.
  String getFormattedPerimeter(MeasurementUnit unit, {int decimals = 2}) {
    return UnitConverter.formatLength(perimeter, unit, decimals: decimals);
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is RoomDimensions &&
        other.length == length &&
        other.width == width &&
        other.height == height;
  }
  
  @override
  int get hashCode => Object.hash(length, width, height);
  
  /// Returns a string representation with the specified unit system.
  String toStringWithUnit(MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.metric:
        return 'RoomDimensions(length: ${length.toStringAsFixed(2)}m, '
               'width: ${width.toStringAsFixed(2)}m, '
               'height: ${height.toStringAsFixed(2)}m)';
      case MeasurementUnit.imperial:
        return 'RoomDimensions(length: ${lengthInFeet.toStringAsFixed(2)}ft, '
               'width: ${widthInFeet.toStringAsFixed(2)}ft, '
               'height: ${heightInFeet.toStringAsFixed(2)}ft)';
    }
  }
  
  @override
  String toString() {
    return 'RoomDimensions(length: ${length.toStringAsFixed(2)}m, '
           'width: ${width.toStringAsFixed(2)}m, '
           'height: ${height.toStringAsFixed(2)}m)';
  }
}
