import 'package:flutter/material.dart';

class UnsupportedCard extends StatelessWidget {
  const UnsupportedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'RoomPlan requires:\n'
          '• iOS 17.0 or later\n'
          '• Device with LiDAR sensor\n'
          '• iPhone 12 Pro or newer Pro models\n'
          '• iPad Pro with LiDAR',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
