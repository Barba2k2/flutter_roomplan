import 'room_dimensions.dart';

class DoorWindowMeasurement {
  final String id;
  final String category;
  final RoomDimensions dimensions;
  final Map<String, double> position;
  final String confidence;
  final double area;

  DoorWindowMeasurement({
    required this.id,
    required this.category,
    required this.dimensions,
    required this.position,
    required this.confidence,
    required this.area,
  });

  factory DoorWindowMeasurement.fromJson(Map<String, dynamic> json) {
    final categoryMap = json['category'] as Map<String, dynamic>?;
    final category = categoryMap?.keys.first ?? 'unknown';
    final confidenceMap = json['confidence'] as Map<String, dynamic>?;
    final confidence = confidenceMap?.keys.first ?? 'low';
    final dimensions = RoomDimensions.fromList(
      json['dimensions'] as List<dynamic>,
    );

    return DoorWindowMeasurement(
      id: json['identifier'] as String,
      category: category,
      dimensions: dimensions,
      position: const {}, // Position data not available in this format
      confidence: confidence,
      area: dimensions.width * dimensions.height,
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
      'category': category,
      'dimensions': dimensions.toJson(),
      'position': position,
      'confidence': confidence,
      'area': area,
    };
  }
}
