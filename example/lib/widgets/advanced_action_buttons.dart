import 'package:flutter/material.dart';

/// Bottom action buttons of the advanced scanning page: Start / Stop scan
/// and (when a result exists) View Detailed Results.
class AdvancedActionButtons extends StatelessWidget {
  const AdvancedActionButtons({
    super.key,
    required this.isScanning,
    required this.hasResult,
    required this.onStartScan,
    required this.onStopScan,
    required this.onShowResults,
  });

  final bool isScanning;
  final bool hasResult;
  final VoidCallback onStartScan;
  final VoidCallback onStopScan;
  final VoidCallback onShowResults;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isScanning)
          ElevatedButton.icon(
            onPressed: onStopScan,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Scanning'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: onStartScan,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Room Scan'),
          ),
        const SizedBox(height: 8),
        if (hasResult)
          OutlinedButton.icon(
            onPressed: onShowResults,
            icon: const Icon(Icons.info),
            label: const Text('View Detailed Results'),
          ),
      ],
    );
  }
}
