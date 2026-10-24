import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class ConfigurationCard extends StatelessWidget {
  final MeasurementUnit unit;
  final ScanConfiguration config;

  const ConfigurationCard({
    super.key,
    required this.unit,
    required this.config,
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
              'Current Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
                'Units: ${unit.displayName} (${unit.lengthUnit}, ${unit.areaUnit})'),
            Text('Quality: ${config.quality.name}'),
            Text('Timeout: ${config.timeoutSeconds ?? 'None'} seconds'),
            Text(
                'Real-time updates: ${config.enableRealtimeUpdates ? 'Enabled' : 'Disabled'}'),
            Text('Detect furniture: ${config.detectFurniture ? 'Yes' : 'No'}'),
          ],
        ),
      ),
    );
  }
}
