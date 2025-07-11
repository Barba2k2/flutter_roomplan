# Flutter RoomPlan

A Flutter plugin that allows you to use Apple's [RoomPlan API](https://developer.apple.com/augmented-reality/roomplan/) to scan an interior room and get a 3D model and measurements.

## Requirements

- iOS 16.0+
- A device with a LiDAR sensor is required (e.g., iPhone 12 Pro or newer Pro models, iPad Pro).

## Installation

First, add `roomplan_flutter` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  roomplan_flutter: ^0.0.5 # Replace with the latest version
```

Then, add the required `NSCameraUsageDescription` to your `ios/Runner/Info.plist` file to explain why your app needs camera access:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan your room and create a 3D model.</string>
```

Finally, run `flutter pub get`.

## Usage

Here's a basic example of how to use the `RoomPlanScanner` in a Flutter widget.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class ScannerWidget extends StatefulWidget {
  const ScannerWidget({super.key});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  late final RoomPlanScanner _roomScanner;
  StreamSubscription<ScanResult>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _roomScanner = RoomPlanScanner();

    // Listen to real-time updates
    _scanSubscription = _roomScanner.onScanResult.listen((result) {
      print('Room updated! Walls: ${result.room.walls.length}');
    });
  }

  @override
  void dispose() {
    // It's important to cancel the subscription and dispose the scanner
    _scanSubscription?.cancel();
    _roomScanner.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      final result = await _roomScanner.startScanning();
      // Use the final result
      print('Scan complete! Room has ${result?.room.walls.length} walls.');
    } on ScanCancelledException {
      print('Scan was cancelled by the user.');
    } catch (e) {
      print('Error finishing scan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _startScan,
      child: const Text('Start Scan'),
    );
  }
}
```

See the `example` app for a more detailed implementation.

## Data Models

The plugin returns a `ScanResult` object, which contains a tree of structured data.

- `ScanResult`: The root object containing the full scan details.

  - `room`: A `RoomData` object with information about the scanned room.
  - `metadata`: A `ScanMetadata` object with details about the session.
  - `confidence`: A `ScanConfidence` object indicating the scan's quality.

- `RoomData`: Contains the physical properties of the room.

  - `dimensions`: A `RoomDimensions` object (`length`, `width`, `height`).
  - `walls`: A list of `WallData` objects.
  - `objects`: A list of `ObjectData` objects (e.g., table, chair).
  - `doors`: A list of `OpeningData` for doors.
  - `windows`: A list of `OpeningData` for windows.
  - `floor`: A `WallData` object representing the floor.
  - `ceiling`: A `WallData` object representing the ceiling.

- `WallData`, `ObjectData`, `OpeningData`: These models describe a physical entity and share common fields:

  - `uuid`: A unique identifier for the entity.
  - `position`: A `Position` object (`Vector3`) representing the center point.
  - `dimensions`: Detailed dimensions (`width`, `height`, `depth`) from the native API.
  - `transform`: A `Matrix4` object for the 3D transform (position, rotation).
  - `confidence`: An enum (`Confidence.low`, `medium`, `high`) for the detected entity.

- `ScanMetadata`: Contains metadata about the scanning session.

  - `scanDuration`: A `Duration` object.
  - `scanDate`: The `DateTime` when the scan started.
  - `deviceModel`: The model of the device (e.g., "iPhone14,3").
  - `hasLidar`: A boolean indicating if the device has a LiDAR sensor.

- `ScanConfidence`: Contains confidence values for different aspects of the scan.
  - `overall`: A `double` from 0.0 to 1.0.
  - `wallAccuracy`: A `double` for the accuracy of wall detection.
  - `dimensionAccuracy`: A `double` for the accuracy of measurements.

Refer to the source code for detailed information on all fields.
