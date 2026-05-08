import 'package:flutter/material.dart';

/// Static instructional card shown at the bottom of the scanner page
/// summarising the RoomPlan flow and the device requirements.
class ScannerInstructionsCard extends StatelessWidget {
  const ScannerInstructionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'How to Use:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('1. Tap "Start Room Scan" to begin'),
            const Text('2. Point your device around the room slowly'),
            const Text('3. Follow the on-screen guidance from RoomPlan'),
            const Text('4. Tap "Done" when the room is fully captured'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Requires iOS 16+ and a device with LiDAR sensor (iPhone 12 Pro or newer Pro models, iPad Pro)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
