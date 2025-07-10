import 'package:example/src/widgets/detail_row.dart';
import 'package:example/src/widgets/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class RoomDetailsView extends StatelessWidget {
  final ScanResult scanResult;

  const RoomDetailsView({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final dimensions = scanResult.room.dimensions;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (dimensions != null)
          MeasurementCard(
            title: 'Room Dimensions',
            details: [
              DetailRow(
                title: 'Length',
                value: '${dimensions.length.toStringAsFixed(2)} m',
              ),
              DetailRow(
                title: 'Width',
                value: '${dimensions.width.toStringAsFixed(2)} m',
              ),
              DetailRow(
                title: 'Height',
                value: '${dimensions.height.toStringAsFixed(2)} m',
              ),
            ],
          ),
      ],
    );
  }
}
