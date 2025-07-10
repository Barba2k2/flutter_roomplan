import 'package:example/src/utils/colors.dart';
import 'package:example/src/widgets/detail_row.dart';
import 'package:example/src/widgets/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class WallsDetailsView extends StatelessWidget {
  final ScanResult scanResult;

  const WallsDetailsView({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final walls = scanResult.room.walls;
    if (walls.isEmpty) {
      return const Center(child: Text('No walls detected.'));
    }
    return ListView.builder(
      itemCount: walls.length,
      itemBuilder: (context, index) {
        final wall = walls[index];
        return MeasurementCard(
          title: 'Wall ${index + 1}',
          details: [
            DetailRow(
              title: 'Width',
              value: '${wall.width.toStringAsFixed(2)} m',
            ),
            DetailRow(
              title: 'Height',
              value: '${wall.height.toStringAsFixed(2)} m',
            ),
            DetailRow(
              title: 'Confidence',
              value: wall.confidence.name,
              valueColor: getColorForConfidence(wall.confidence),
            ),
          ],
        );
      },
    );
  }
}
