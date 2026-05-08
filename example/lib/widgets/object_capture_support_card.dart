import 'package:flutter/material.dart';

/// Coloured banner showing whether the running device supports Apple's
/// Object Capture pipeline. Driven by a `bool?` state that the owning
/// view model is responsible for resolving (via
/// `FlutterObjectCapture.isSupported()`).
class ObjectCaptureSupportCard extends StatelessWidget {
  const ObjectCaptureSupportCard({super.key, required this.isSupported});

  /// `null` while the support probe is in flight, then `true` / `false`.
  final bool? isSupported;

  @override
  Widget build(BuildContext context) {
    final label = switch (isSupported) {
      null => 'Checking device support…',
      true => 'Object Capture supported',
      false => 'Object Capture NOT supported on this device',
    };
    final color = switch (isSupported) {
      null => Colors.grey,
      true => Colors.green,
      false => Colors.red,
    };
    return Card(
      color: color.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(Icons.camera_alt, color: color),
        title: Text(label),
      ),
    );
  }
}
