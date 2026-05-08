import 'package:flutter/material.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';

/// Summary tile for a completed [ObjectCaptureResult]: photo count, capture
/// duration, and the on-disk path of the produced images folder.
class ObjectCaptureResultCard extends StatelessWidget {
  const ObjectCaptureResultCard({super.key, required this.result});

  final ObjectCaptureResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: const Text('Capture complete'),
        subtitle: Text(
          '${result.captureCount} photos in '
          '${result.duration.inSeconds}s\n${result.imagesFolderPath}',
        ),
      ),
    );
  }
}
