import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Read-only summary of the current scan configuration and unit selection on
/// the advanced scanning page.
class AdvancedConfigurationCard extends StatelessWidget {
  const AdvancedConfigurationCard({
    super.key,
    required this.configuration,
    required this.unit,
  });

  final ScanConfiguration configuration;
  final MeasurementUnit unit;

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
              'Units: ${unit.displayName} (${unit.lengthUnit}, ${unit.areaUnit})',
            ),
            Text('Quality: ${configuration.quality.name}'),
            Text(
              'Timeout: ${configuration.timeoutSeconds ?? 'None'} seconds',
            ),
            Text(
              'Real-time updates: '
              '${configuration.enableRealtimeUpdates ? 'Enabled' : 'Disabled'}',
            ),
            Text(
              'Detect furniture: '
              '${configuration.detectFurniture ? 'Yes' : 'No'}',
            ),
          ],
        ),
      ),
    );
  }
}
