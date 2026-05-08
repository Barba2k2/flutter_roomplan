import 'package:flutter/material.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';

/// Renders the most recent [CaptureEvent] emitted by the plugin's event
/// stream. State name in the title, optional progress / message / error in
/// the subtitle.
class ObjectCaptureEventCard extends StatelessWidget {
  const ObjectCaptureEventCard({super.key, required this.event});

  final CaptureEvent event;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (event.progress != null)
        'Progress: ${(event.progress! * 100).toStringAsFixed(1)}%',
      if (event.message != null) event.message!,
      if (event.error != null) 'Error: ${event.error}',
    ];

    return Card(
      child: ListTile(
        leading: const Icon(Icons.bolt),
        title: Text('Last event: ${event.state.name}'),
        subtitle: lines.isEmpty ? null : Text(lines.join('\n')),
      ),
    );
  }
}
