import 'package:flutter/material.dart';

/// Status card shown at the top of the advanced scanning page. Displays the
/// current view-model status text and, while scanning, the elapsed duration.
class AdvancedStatusCard extends StatelessWidget {
  const AdvancedStatusCard({
    super.key,
    required this.statusMessage,
    required this.isScanning,
    required this.scanDuration,
  });

  final String statusMessage;
  final bool isScanning;
  final String scanDuration;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(statusMessage),
            if (isScanning) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('Duration: $scanDuration'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
