import 'package:example/widgets/detail_row.dart';
import 'package:example/widgets/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class OpeningsDetailsView extends StatelessWidget {
  final ScanResult scanResult;

  const OpeningsDetailsView({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final doors = scanResult.room.doors;
    final windows = scanResult.room.windows;

    if (doors.isEmpty && windows.isEmpty) {
      return const Center(child: Text('No doors or windows detected.'));
    }

    return ListView(
      children: [
        ...doors.map(
          (door) => MeasurementCard(
            title: 'Door',
            details: [
              DetailRow(
                title: 'Width',
                value: '${door.width.toStringAsFixed(2)} m',
              ),
              DetailRow(
                title: 'Height',
                value: '${door.height.toStringAsFixed(2)} m',
              ),
            ],
          ),
        ),
        ...windows.map(
          (window) => MeasurementCard(
            title: 'Window',
            details: [
              DetailRow(
                title: 'Width',
                value: '${window.width.toStringAsFixed(2)} m',
              ),
              DetailRow(
                title: 'Height',
                value: '${window.height.toStringAsFixed(2)} m',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
