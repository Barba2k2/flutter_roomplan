import 'room_dimensions.dart';

class WallMeasurement {
  final String id;
  final RoomDimensions dimensions;
  final Map<String, double> position;
  final String confidence;
  final double area;
  final double perimeter;

  WallMeasurement({
    required this.id,
    required this.dimensions,
    required this.position,
    required this.confidence,
    required this.area,
    required this.perimeter,
  });

  factory WallMeasurement.fromJson(Map<String, dynamic> json) {
    final confidenceMap = json['confidence'] as Map<String, dynamic>?;
    final confidence = confidenceMap?.keys.first ?? 'low';
    final dimensions = RoomDimensions.fromList(
      json['dimensions'] as List<dynamic>,
    );

    return WallMeasurement(
      id: json['identifier'] as String,
      dimensions: dimensions,
      position: const {}, // Position data not available in this format
      confidence: confidence,
      area: dimensions.width * dimensions.height,
      perimeter: 2 * (dimensions.width + dimensions.height),
    );
  }

  String get confidenceText {
    switch (confidence) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Média';
      default:
        return 'Baixa';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dimensions': dimensions.toJson(),
      'position': position,
      'confidence': confidence,
      'area': area,
      'perimeter': perimeter,
    };
  }
}
