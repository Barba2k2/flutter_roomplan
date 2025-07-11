import 'package:example/src/widgets/detail_row.dart';
import 'package:example/src/widgets/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class PaintAreaDetailsView extends StatelessWidget {
  final ScanResult scanResult;

  const PaintAreaDetailsView({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final walls = scanResult.room.walls;
    if (walls.isEmpty) {
      return const Center(child: Text('No walls detected.'));
    }

    double totalPaintableArea = 0;
    final wallDetails = <Widget>[];

    for (int i = 0; i < walls.length; i++) {
      final wall = walls[i];
      final wallArea = wall.width * wall.height;

      double openingsArea = 0;
      for (var opening in wall.openings) {
        openingsArea += opening.width * opening.height;
      }

      final paintableArea = (wallArea - openingsArea).clamp(0, double.infinity);
      totalPaintableArea += paintableArea;

      wallDetails.add(
        MeasurementCard(
          title: 'Wall ${i + 1}',
          details: [
            DetailRow(
              title: 'Total Area',
              value: '${wallArea.toStringAsFixed(2)} m²',
            ),
            DetailRow(
              title: 'Openings Area',
              value: '- ${openingsArea.toStringAsFixed(2)} m²',
              valueColor: Colors.red.shade700,
            ),
            const Divider(),
            DetailRow(
              title: 'Paintable Area',
              value: '${paintableArea.toStringAsFixed(2)} m²',
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: MeasurementCard(
            title: 'Room Summary',
            details: [
              DetailRow(
                title: 'Total Paintable Area',
                value: '${totalPaintableArea.toStringAsFixed(2)} m²',
              ),
            ],
          ),
        ),
        ...wallDetails,
      ],
    );
  }
}
