import 'package:example/src/utils/colors.dart';
import 'package:example/src/utils/strings.dart';
import 'package:example/src/widgets/detail_row.dart';
import 'package:example/src/widgets/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class ObjectsDetailsView extends StatelessWidget {
  final ScanResult scanResult;

  const ObjectsDetailsView({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final objects = scanResult.room.objects;
    if (objects.isEmpty) {
      return const Center(child: Text('No objects detected.'));
    }
    return ListView.builder(
      itemCount: objects.length,
      itemBuilder: (context, index) {
        final object = objects[index];
        return MeasurementCard(
          title: capitalize(object.category.name),
          details: [
            DetailRow(
              title: 'Length',
              value: '${object.length.toStringAsFixed(2)} m',
            ),
            DetailRow(
              title: 'Width',
              value: '${object.width.toStringAsFixed(2)} m',
            ),
            DetailRow(
              title: 'Height',
              value: '${object.height.toStringAsFixed(2)} m',
            ),
            DetailRow(
              title: 'Confidence',
              value: object.confidence.name,
              valueColor: getColorForConfidence(object.confidence),
            ),
          ],
        );
      },
    );
  }
}
