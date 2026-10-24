import 'package:example/widgets/scanner/scanner_data_row.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// The real-time scan data display card.
class ScanDataCard extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const ScanDataCard({super.key, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Real-time Scan Data',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ScannerDataRow(
                label: 'Walls',
                value: '${result.room.walls.length}',
                icon: Icons.square_outlined,
              ),
              ScannerDataRow(
                label: 'Doors',
                value: '${result.room.doors.length}',
                icon: Icons.door_front_door,
              ),
              ScannerDataRow(
                label: 'Windows',
                value: '${result.room.windows.length}',
                icon: Icons.window,
              ),
              ScannerDataRow(
                label: 'Openings',
                value: '${result.room.openings.length}',
                icon: Icons.open_in_new,
              ),
              ScannerDataRow(
                label: 'Objects',
                value: '${result.room.objects.length}',
                icon: Icons.chair,
              ),
              const Divider(),
              ScannerDataRow(
                label: 'LiDAR Available',
                value: result.metadata.hasLidar ? 'Yes' : 'No',
                icon: Icons.radar,
              ),
              ScannerDataRow(
                label: 'Device',
                value: result.metadata.deviceModel,
                icon: Icons.phone_iphone,
              ),
              if (result.room.dimensions != null)
                ScannerDataRow(
                  label: 'Room Size',
                  value:
                      '${result.room.dimensions!.width.toStringAsFixed(1)}m × ${result.room.dimensions!.length.toStringAsFixed(1)}m',
                  icon: Icons.straighten,
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view results',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
