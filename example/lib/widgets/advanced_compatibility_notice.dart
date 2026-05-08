import 'package:flutter/material.dart';

/// Static notice shown on the advanced scanning page when the device is not
/// compatible with RoomPlan.
class AdvancedCompatibilityNotice extends StatelessWidget {
  const AdvancedCompatibilityNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'RoomPlan requires:\n'
          '• iOS 16.0 or later\n'
          '• Device with LiDAR sensor\n'
          '• iPhone 12 Pro or newer Pro models\n'
          '• iPad Pro with LiDAR',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
