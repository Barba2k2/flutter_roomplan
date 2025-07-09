import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Represents the final result of a successful room scan.
class ScanResult {
  /// The structured data of the scanned room, including walls and objects.
  final RoomData room;

  /// Metadata associated with the scanning session.
  final ScanMetadata metadata;

  /// Confidence levels for various aspects of the scan.
  final ScanConfidence confidence;

  /// Creates a [ScanResult] object.
  const ScanResult({
    required this.room,
    required this.metadata,
    required this.confidence,
  });
}
