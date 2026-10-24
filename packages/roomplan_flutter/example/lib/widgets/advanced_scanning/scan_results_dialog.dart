import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class ScanResultsDialog extends StatelessWidget {
  final ScanResult result;
  final MeasurementUnit unit;

  const ScanResultsDialog({
    super.key,
    required this.result,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Results'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Room Dimensions (${unit.displayName}):'),
            if (result.room.dimensions != null) ...[
              Text(
                '  Length: ${result.room.dimensions!.getFormattedLength(unit)}',
              ),
              Text(
                '  Width: ${result.room.dimensions!.getFormattedWidth(unit)}',
              ),
              Text(
                '  Height: ${result.room.dimensions!.getFormattedHeight(unit)}',
              ),
              Text(
                '  Floor Area: ${result.room.dimensions!.getFormattedFloorArea(unit)}',
              ),
              Text(
                '  Volume: ${result.room.dimensions!.getFormattedVolume(unit)}',
              ),
            ] else
              const Text('  Not available'),
            const SizedBox(height: 16),
            const Text('Scan Metadata:'),
            Text(
              '  Duration: ${result.metadata.scanDuration.inSeconds}s',
            ),
            Text('  Device: ${result.metadata.deviceModel}'),
            Text('  Has LiDAR: ${result.metadata.hasLidar ? 'Yes' : 'No'}'),
            const SizedBox(height: 16),
            const Text('Confidence Scores:'),
            Text(
              '  Overall: ${(result.confidence.overall * 100).toStringAsFixed(1)}%',
            ),
            Text(
              '  Wall Accuracy: ${(result.confidence.wallAccuracy * 100).toStringAsFixed(1)}%',
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
