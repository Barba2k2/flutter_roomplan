import 'package:example/widgets/advanced_scanning/statistic_item.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class StatisticsCard extends StatelessWidget {
  final int wallsDetected;
  final int objectsDetected;
  final int doorsDetected;
  final int windowsDetected;
  final ScanResult? currentResult;
  final MeasurementUnit unit;

  const StatisticsCard({
    super.key,
    required this.wallsDetected,
    required this.objectsDetected,
    required this.doorsDetected,
    required this.windowsDetected,
    required this.currentResult,
    required this.unit,
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
            const SizedBox(height: 12),
            if (currentResult?.room.floor != null ||
                currentResult?.room.ceiling != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Floor/Ceiling',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (currentResult?.room.floor != null)
                    Text(
                      'Floor area: '
                      '${currentResult!.room.floor!.dimensions?.getFormattedFloorArea(unit) ?? '—'}',
                    ),
                  if (currentResult?.room.ceiling != null)
                    Text(
                      'Ceiling area: '
                      '${currentResult!.room.ceiling!.dimensions?.getFormattedFloorArea(unit) ?? '—'}',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
