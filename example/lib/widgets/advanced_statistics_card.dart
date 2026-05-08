import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

import 'package:example/widgets/statistic_item.dart';

/// Detection statistics card shown on the advanced scanning page.
///
/// Displays counts for walls / objects / doors / windows plus the formatted
/// floor and ceiling areas when the latest [ScanResult] exposes them.
class AdvancedStatisticsCard extends StatelessWidget {
  const AdvancedStatisticsCard({
    super.key,
    required this.wallsDetected,
    required this.objectsDetected,
    required this.doorsDetected,
    required this.windowsDetected,
    required this.unit,
    this.currentResult,
  });

  final int wallsDetected;
  final int objectsDetected;
  final int doorsDetected;
  final int windowsDetected;
  final MeasurementUnit unit;
  final ScanResult? currentResult;

  @override
  Widget build(BuildContext context) {
    final floor = currentResult?.room.floor;
    final ceiling = currentResult?.room.ceiling;
    final hasFloorOrCeiling = floor != null || ceiling != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatisticItem(
                  icon: Icons.crop_square,
                  label: 'Walls',
                  count: wallsDetected,
                ),
                StatisticItem(
                  icon: Icons.chair,
                  label: 'Objects',
                  count: objectsDetected,
                ),
                StatisticItem(
                  icon: Icons.door_front_door,
                  label: 'Doors',
                  count: doorsDetected,
                ),
                StatisticItem(
                  icon: Icons.window,
                  label: 'Windows',
                  count: windowsDetected,
                ),
              ],
            ),
            if (hasFloorOrCeiling) ...[
              const SizedBox(height: 12),
              Text(
                'Floor/Ceiling',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (floor != null)
                Text(
                  'Floor area: '
                  '${floor.dimensions?.getFormattedFloorArea(unit) ?? '—'}',
                ),
              if (ceiling != null)
                Text(
                  'Ceiling area: '
                  '${ceiling.dimensions?.getFormattedFloorArea(unit) ?? '—'}',
                ),
            ],
          ],
        ),
      ),
    );
  }
}
