import 'package:example/widgets/detail_row.dart';
import 'package:example/widgets/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class RoomDetailsView extends StatelessWidget {
  final ScanResult scanResult;

  const RoomDetailsView({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final dimensions = scanResult.room.dimensions;
    final floor = scanResult.room.floor;
    final ceiling = scanResult.room.ceiling;
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
        if (floor != null)
          MeasurementCard(
            title: 'Floor',
            details: [
              if (floor.dimensions != null) ...[
                DetailRow(
                  title: 'Length',
                  value: floor.dimensions!
                      .getFormattedLength(MeasurementUnit.metric),
                ),
                DetailRow(
                  title: 'Width',
                  value: floor.dimensions!
                      .getFormattedWidth(MeasurementUnit.metric),
                ),
                DetailRow(
                  title: 'Area',
                  value: floor.dimensions!
                      .getFormattedFloorArea(MeasurementUnit.metric),
                ),
              ],
              DetailRow(
                title: 'Confidence',
                value: floor.confidence.toString().split('.').last,
              ),
            ],
          ),
        if (ceiling != null)
          MeasurementCard(
            title: 'Ceiling',
            details: [
              if (ceiling.dimensions != null) ...[
                DetailRow(
                  title: 'Length',
                  value: ceiling.dimensions!
                      .getFormattedLength(MeasurementUnit.metric),
                ),
                DetailRow(
                  title: 'Width',
                  value: ceiling.dimensions!
                      .getFormattedWidth(MeasurementUnit.metric),
                ),
                DetailRow(
                  title: 'Area',
                  value: ceiling.dimensions!
                      .getFormattedFloorArea(MeasurementUnit.metric),
                ),
              ],
              DetailRow(
                title: 'Confidence',
                value: ceiling.confidence.toString().split('.').last,
              ),
            ],
          ),
      ],
    );
  }
}
