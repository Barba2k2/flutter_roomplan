import 'package:flutter/material.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';

/// Summary tile for a completed [PhotogrammetryResult]: detail level,
/// processing time, and the on-disk path of the produced `.usdz` model.
class PhotogrammetryResultCard extends StatelessWidget {
  const PhotogrammetryResultCard({super.key, required this.result});

  final PhotogrammetryResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.view_in_ar),
        title: const Text('Reconstruction complete'),
        subtitle: Text(
          '${result.detailLevel.name} • '
          '${result.processingTime.inSeconds}s\n${result.modelPath}',
        ),
      ),
    );
  }
}
