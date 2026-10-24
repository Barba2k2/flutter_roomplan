import 'package:example/widgets/detail_row.dart';
import 'package:example/widgets/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class OpeningsDetailsView extends StatelessWidget {
  final ScanResult scanResult;

  const OpeningsDetailsView({
    super.key,
    required this.scanResult,
  });

  @override
  Widget build(BuildContext context) {
    final room = scanResult.room;
    final items = [
      ...room.doors.map(
        (o) => (
          'Door',
          o,
        ),
      ),
      ...room.windows.map(
        (o) => (
          'Window',
          o,
        ),
      ),
      ...room.openings.map(
        (o) => (
          'Opening',
          o,
        ),
      ),
    ];

    if (items.isEmpty) {
      return const Center(
        child: Text('No doors, windows or openings detected.'),
      );
    }

    return ListView(
      children: [
        for (final (label, opening) in items)
          MeasurementCard(
            title: label,
            details: [
              DetailRow(
                title: 'Width',
                value: '${opening.width.toStringAsFixed(2)} m',
              ),
              DetailRow(
                title: 'Height',
                value: '${opening.height.toStringAsFixed(2)} m',
              ),
            ],
          ),
      ],
    );
  }
}
