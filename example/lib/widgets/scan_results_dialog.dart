import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Dialog summarising a [ScanResult]: room dimensions in the user's
/// preferred [MeasurementUnit], scan metadata, and confidence scores.
class ScanResultsDialog extends StatelessWidget {
  const ScanResultsDialog({
    super.key,
    required this.result,
    required this.unit,
  });

  final ScanResult result;
  final MeasurementUnit unit;

  @override
  Widget build(BuildContext context) {
    final dimensions = result.room.dimensions;
    final metadata = result.metadata;
    final confidence = result.confidence;

    return AlertDialog(
      title: const Text('Scan Results'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Room Dimensions (${unit.displayName}):'),
            if (dimensions != null) ...[
              Text('  Length: ${dimensions.getFormattedLength(unit)}'),
              Text('  Width: ${dimensions.getFormattedWidth(unit)}'),
              Text('  Height: ${dimensions.getFormattedHeight(unit)}'),
              Text(
                '  Floor Area: ${dimensions.getFormattedFloorArea(unit)}',
              ),
              Text('  Volume: ${dimensions.getFormattedVolume(unit)}'),
            ] else
              const Text('  Not available'),
            const SizedBox(height: 16),
            const Text('Scan Metadata:'),
            Text('  Duration: ${metadata.scanDuration.inSeconds}s'),
            Text('  Device: ${metadata.deviceModel}'),
            Text('  Has LiDAR: ${metadata.hasLidar ? 'Yes' : 'No'}'),
            const SizedBox(height: 16),
            const Text('Confidence Scores:'),
            Text(
              '  Overall: ${(confidence.overall * 100).toStringAsFixed(1)}%',
            ),
            Text(
              '  Wall Accuracy: '
              '${(confidence.wallAccuracy * 100).toStringAsFixed(1)}%',
            ),
            Text(
              '  Dimension Accuracy: '
              '${(confidence.dimensionAccuracy * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
