# Flutter RoomPlan

A Flutter plugin that allows you to use Apple's [RoomPlan API](https://developer.apple.com/augmented-reality/roomplan/) to scan an interior room and get a 3D model and measurements.

## Requirements

- iOS 16.0+
- A device with a LiDAR sensor is required (e.g., iPhone 12 Pro or newer Pro models, iPad Pro).

## Installation

First, add `roomplan_flutter` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  roomplan_flutter: ^0.0.3 # Replace with the latest version
```

Then, add the required `NSCameraUsageDescription` to your `ios/Runner/Info.plist` file to explain why your app needs camera access:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan your room and create a 3D model.</string>
```

Finally, run `flutter pub get`.

## Usage

Here's a basic example of how to use the `RoomPlanScanner`.

```dart
import 'package:roomplan_flutter/roomplan_flutter.dart';

// 1. Create a scanner instance
final _roomScanner = RoomPlanScanner();

// 2. (Optional) Listen to real-time updates
_roomScanner.onScanResult.listen((result) {
  print('Room updated! Walls: ${result.room.walls.length}, Objects: ${result.room.objects.length}');
});

// 3. Start the scan and await the final result
try {
  final result = await _roomScanner.startScanning();
  print('Scan complete! Room has ${result?.room.walls.length} walls.');
} on ScanCancelledException {
  print('Scan was cancelled by the user.');
} catch (e) {
  print('Error finishing scan: $e');
}

// 4. Don't forget to dispose the scanner
_roomScanner.dispose();
```

See the `example` app for a more detailed implementation.

## Data Models

The plugin returns a `ScanResult` object which contains the following structured data:

- `ScanResult`:
  - `room`: A `RoomData` object.
  - `metadata`: A `ScanMetadata` object.
  - `confidence`: A `ScanConfidence` object.
- `RoomData`:
  - `dimensions`: Overall room dimensions (`length`, `width`, `height`).
  - `walls`: A list of `WallData` objects.
  - `objects`: A list of `ObjectData` objects.
  - `doors`: A list of `OpeningData` objects.
  - `windows`: A list of `OpeningData` objects.
- `WallData`/`OpeningData`:
  - `uuid`, `dimensions`, `confidence`, etc.

Refer to the source code for detailed information on each model.
