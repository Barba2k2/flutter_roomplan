import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String statusMessage;
  final bool isScanning;
  final String scanDuration;

  const StatusCard({
    super.key,
    required this.statusMessage,
    required this.isScanning,
    required this.scanDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
