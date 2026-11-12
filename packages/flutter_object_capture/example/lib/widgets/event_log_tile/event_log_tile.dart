import 'package:flutter/material.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import '../../helpers/event_log_text_helper.dart';

class EventLogTile extends StatelessWidget {
  const EventLogTile({super.key, required this.event});

  final ReconstructionEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIssue = event is ReconstructionSampleIssue;
    return ListTile(
      dense: true,
      leading: Icon(
        isIssue ? Icons.warning_amber : Icons.info_outline,
        size: 24,
        color: isIssue ? scheme.error : scheme.primary,
      ),
      title: Text(
        EventLogTextHelper.describe(event),
      ),
    );
  }
}
