import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

import 'package:example/widgets/scan_data_row.dart';

/// Real-time summary of the most recent [ScanResult]: counts of structural
/// elements, device metadata, and (when available) the room's bounding
/// dimensions.
class ScanDataCard extends StatelessWidget {
  const ScanDataCard({super.key, required this.scanResult});

  final ScanResult scanResult;

  @override
  Widget build(BuildContext context) {
    final room = scanResult.room;
    final metadata = scanResult.metadata;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Real-time Scan Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ScanDataRow(
              label: 'Walls',
              value: '${room.walls.length}',
              icon: Icons.square_outlined,
            ),
            ScanDataRow(
              label: 'Doors',
              value: '${room.doors.length}',
              icon: Icons.door_front_door,
            ),
            ScanDataRow(
              label: 'Windows',
              value: '${room.windows.length}',
              icon: Icons.window,
            ),
            ScanDataRow(
              label: 'Openings',
              value: '${room.openings.length}',
              icon: Icons.open_in_new,
            ),
            ScanDataRow(
              label: 'Objects',
              value: '${room.objects.length}',
              icon: Icons.chair,
            ),
            const Divider(),
            ScanDataRow(
              label: 'LiDAR Available',
              value: metadata.hasLidar ? 'Yes' : 'No',
              icon: Icons.radar,
            ),
            ScanDataRow(
              label: 'Device',
              value: metadata.deviceModel,
              icon: Icons.phone_iphone,
            ),
            if (room.dimensions != null)
              ScanDataRow(
                label: 'Room Size',
                value:
                    '${room.dimensions!.width.toStringAsFixed(1)}m × ${room.dimensions!.length.toStringAsFixed(1)}m',
                icon: Icons.straighten,
              ),
          ],
        ),
      ),
    );
  }
}
