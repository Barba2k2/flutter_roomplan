import 'package:example/widgets/detail_row.dart';
import 'package:example/widgets/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class FloorCeilingDetailsView extends StatelessWidget {
  final WallData? floor;
  final WallData? ceiling;
  final MeasurementUnit unit;

  const FloorCeilingDetailsView({
    super.key,
    required this.floor,
    required this.ceiling,
    this.unit = MeasurementUnit.metric,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (floor != null) {
      items.add(
        MeasurementCard(
          title: 'Floor',
          details: [
            if (floor!.dimensions != null) ...[
              DetailRow(
                title: 'Length',
                value: floor!.dimensions!.getFormattedLength(unit),
              ),
              DetailRow(
                title: 'Width',
                value: floor!.dimensions!.getFormattedWidth(unit),
              ),
              DetailRow(
                title: 'Area',
                value: floor!.dimensions!.getFormattedFloorArea(unit),
              ),
            ],
            DetailRow(
              title: 'Confidence',
              value: floor!.confidence.toString().split('.').last,
            ),
          ],
        ),
      );
    }

    if (ceiling != null) {
      items.add(
        MeasurementCard(
          title: 'Ceiling',
          details: [
            if (ceiling!.dimensions != null) ...[
              DetailRow(
                title: 'Length',
                value: ceiling!.dimensions!.getFormattedLength(unit),
              ),
              DetailRow(
                title: 'Width',
                value: ceiling!.dimensions!.getFormattedWidth(unit),
              ),
              DetailRow(
                title: 'Area',
                value: ceiling!.dimensions!.getFormattedFloorArea(unit),
              ),
            ],
            DetailRow(
              title: 'Confidence',
              value: ceiling!.confidence.toString().split('.').last,
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...items,
      ],
    );
  }
}
