import 'package:example/widgets/detail_row.dart';
import 'package:example/widgets/measurement_card.dart';
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

    final storageByWall = PaintableAreaHelper.storageAreaByWall(
      walls,
      scanResult.room.objects,
    );
    double totalPaintableArea = 0;
    final wallDetails = <Widget>[];

    for (int i = 0; i < walls.length; i++) {
      final wall = walls[i];
      final storageArea = storageByWall[wall.uuid] ?? 0;
      final paintableArea = PaintableAreaHelper.paintableArea(
        wall,
        storageArea: storageArea,
      );
      totalPaintableArea += paintableArea;
      final deductions = {
        'Doors': PaintableAreaHelper.openingsArea(wall, OpeningType.door),
        'Windows': PaintableAreaHelper.openingsArea(wall, OpeningType.window),
        'Openings': PaintableAreaHelper.openingsArea(wall, OpeningType.opening),
        'Built-in cabinets': storageArea,
      };

      wallDetails.add(
        MeasurementCard(
          title: 'Wall ${i + 1}',
          details: [
            DetailRow(
              title: 'Gross Area',
              value:
                  '${PaintableAreaHelper.grossArea(wall).toStringAsFixed(2)} m²',
            ),
            for (final MapEntry(:key, :value) in deductions.entries)
              DetailRow(
                title: key,
                value: '- ${value.toStringAsFixed(2)} m²',
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
