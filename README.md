# Flutter RoomPlan

A Flutter plugin that allows you to use Apple's [RoomPlan API](https://developer.apple.com/augmented-reality/roomplan/) to scan an interior room and get a 3D model and measurements.

## Requirements

- iOS 16.0+
- A device with a LiDAR sensor is required (e.g., iPhone 12 Pro or newer Pro models, iPhone 16 Pro/Pro Max, iPad Pro).

## Installation

First, add `roomplan_flutter` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  roomplan_flutter: ^0.0.8 # Replace with the latest version
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
  StreamSubscription<ScanResult?>? _scanSubscription;
  bool _isSupported = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported = await RoomPlanScanner.isSupported();
    setState(() {
      _isSupported = supported;
    });
    
    if (supported) {
      _roomScanner = RoomPlanScanner();
      
      // Listen to real-time updates
      _scanSubscription = _roomScanner.onScanResult.listen((result) {
        if (result != null) {
          print('Room updated! Walls: ${result.room.walls.length}');
        }
      });
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    if (_isSupported) {
      _roomScanner.dispose();
    }
    super.dispose();
  }

  Future<void> _startScan() async {
    if (!_isSupported) return;
    
    setState(() => _isScanning = true);
    
    try {
      final result = await _roomScanner.startScanning();
      if (result != null) {
        print('Scan complete! Room has ${result.room.walls.length} walls.');
        // Process your scan result here
      }
    } on RoomPlanPermissionsException {
      print('Camera permission denied. Please grant camera access.');
    } on ScanCancelledException {
      print('Scan was cancelled by the user.');
    } catch (e) {
      print('Error during scan: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _stopScan() async {
    if (_isSupported && _isScanning) {
      await _roomScanner.stopScanning();
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'RoomPlan is not supported on this device.\n'
            'Requires iOS 16+ and LiDAR sensor.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isScanning) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _stopScan,
            child: const Text('Stop Scan'),
          ),
        ] else
          ElevatedButton(
            onPressed: _startScan,
            child: const Text('Start Room Scan'),
          ),
      ],
    );
  }
}
```

### Checking Device Compatibility

Before starting a scan, you should check if the device supports RoomPlan:

```dart
final isSupported = await RoomPlanScanner.isSupported();
if (!isSupported) {
  // Show appropriate message to user
  print('RoomPlan requires iOS 16+ and a LiDAR-enabled device');
}
```

### Error Handling

The plugin provides specific exceptions for different error scenarios:

- `RoomPlanPermissionsException`: Camera permission was denied
- `ScanCancelledException`: User cancelled the scan
- `PlatformException`: Other platform-specific errors

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

## Troubleshooting

### Common Issues

**"RoomPlan is not supported"**
- Ensure your device has iOS 16.0 or later
- Verify your device has a LiDAR sensor (iPhone 12 Pro+, iPad Pro with LiDAR)
- Check that your app's deployment target is set to iOS 16.0+

**Camera permission denied**
- Add `NSCameraUsageDescription` to your `Info.plist`
- The user must grant camera permission when prompted
- Users can change permissions in Settings > Privacy & Security > Camera

**Scanning accuracy issues**
- Ensure good lighting conditions
- Move slowly and steadily during scanning
- Keep the camera pointed at walls and objects
- Avoid reflective surfaces and windows when possible

**Memory issues or crashes**
- Always call `dispose()` on the scanner when done
- Cancel stream subscriptions in your widget's `dispose()` method
- Avoid creating multiple scanner instances simultaneously

### Best Practices

1. **Check compatibility first**: Always call `RoomPlanScanner.isSupported()` before creating a scanner
2. **Handle permissions gracefully**: Provide clear messaging when camera access is denied
3. **Provide user guidance**: Show instructions on how to scan effectively
4. **Memory management**: Always dispose resources properly
5. **Error handling**: Implement comprehensive error handling for all scan scenarios

## API Reference

### RoomPlanScanner

#### Static Methods
- `static Future<bool> isSupported()` - Check if RoomPlan is available on the current device

#### Instance Methods
- `Future<ScanResult?> startScanning()` - Begin a room scanning session
- `Future<void> stopScanning()` - Stop the current scanning session
- `void dispose()` - Clean up resources

#### Properties
- `Stream<ScanResult?> onScanResult` - Stream of real-time scan updates

### Exceptions
- `RoomPlanPermissionsException` - Thrown when camera permission is denied
- `ScanCancelledException` - Thrown when user cancels the scan

# Testing Guide for Flutter RoomPlan

## Device Requirements for Testing

### Supported Devices
To properly test the Flutter RoomPlan package, you need a device with:

- **iOS 16.0 or later**
- **LiDAR sensor**

#### Compatible Devices:
- iPhone 12 Pro / Pro Max
- iPhone 13 Pro / Pro Max  
- iPhone 14 Pro / Pro Max
- iPhone 15 Pro / Pro Max
- iPhone 16 Pro / Pro Max
- iPad Pro 11-inch (4th generation and later)
- iPad Pro 12.9-inch (5th generation and later)

### Non-Compatible Devices
These devices will return `isSupported() = false`:
- iPhone 12 / 12 Mini
- iPhone 13 / 13 Mini
- iPhone 14 / 14 Plus
- iPhone 15 / 15 Plus
- iPhone 16 / 16 Plus
- Any device running iOS < 16.0

## Testing Checklist

### 1. Unit Tests
Run automated tests on any development machine:
```bash
flutter test
```

Expected results:
- ✅ All RoomPlanScanner method tests pass
- ✅ All model validation tests pass
- ✅ All exception handling tests pass
- ✅ All JSON parsing tests pass

### 2. Device Compatibility Testing

#### On Compatible Device:
```dart
final isSupported = await RoomPlanScanner.isSupported();
// Should return: true
```

#### On Incompatible Device:
```dart
final isSupported = await RoomPlanScanner.isSupported();
// Should return: false
```

### 3. Permission Testing

#### Test Camera Permission Flow:
1. First run - should prompt for camera permission
2. Grant permission - scanning should work
3. Deny permission - should throw `RoomPlanPermissionsException`
4. Test permission changes in iOS Settings

### 4. Scanning Functionality Tests

#### Basic Scanning Test:
```dart
final scanner = RoomPlanScanner();
try {
  final result = await scanner.startScanning();
  if (result != null) {
    print('✅ Scan completed successfully');
    print('Room dimensions: ${result.room.dimensions}');
    print('Walls found: ${result.room.walls.length}');
    print('Objects found: ${result.room.objects.length}');
  }
} catch (e) {
  print('❌ Scan failed: $e');
}
```

#### Real-time Updates Test:
```dart
final scanner = RoomPlanScanner();
scanner.onScanResult.listen((result) {
  if (result != null) {
    print('📊 Real-time update: ${result.room.walls.length} walls');
  }
});
```

#### Stop Scanning Test:
```dart
final scanner = RoomPlanScanner();
// Start scanning in background
scanner.startScanning();

// Stop after 10 seconds
await Future.delayed(Duration(seconds: 10));
await scanner.stopScanning();
```

### 5. Error Scenario Testing

#### Test Different Error Conditions:
- Camera permission denied
- User cancels scan
- Device orientation changes during scan
- App backgrounding during scan
- Multiple scanner instances
- Memory pressure scenarios

### 6. Performance Testing

#### Memory Usage:
- Monitor memory usage during long scans
- Test multiple scan sessions
- Verify proper resource cleanup with `dispose()`

#### Battery Usage:
- Monitor battery drain during scanning
- Test with screen brightness settings
- Compare performance in different room sizes

### 7. Room Scenarios Testing

#### Test Different Room Types:
- **Small rooms** (< 3x3 meters)
- **Large rooms** (> 6x6 meters)
- **Complex layouts** (L-shaped, multiple doorways)
- **Furnished vs empty rooms**
- **Different lighting conditions**

#### Environmental Challenges:
- **Reflective surfaces** (mirrors, glass)
- **Dark rooms** (poor lighting)
- **Cluttered spaces**
- **Outdoor spaces** (should fail gracefully)

## Test Results Documentation

### Create Test Report:
Document your testing with:

```markdown
## Test Report - Flutter RoomPlan v0.0.8

**Device**: iPhone 14 Pro (iOS 17.1)
**Date**: [Current Date]

### Compatibility Tests
- ✅ isSupported() returns true
- ✅ Camera permission prompt appears
- ✅ Scan initializes successfully

### Functionality Tests  
- ✅ Basic room scan completes
- ✅ Real-time updates received
- ✅ Stop scanning works correctly
- ✅ Room dimensions detected: 4.2m x 3.8m x 2.7m
- ✅ Objects detected: 3 (table, chair, bookshelf)
- ✅ Walls detected: 4
- ✅ Doors detected: 1
- ✅ Windows detected: 2

### Error Handling Tests
- ✅ Permission denied handled correctly
- ✅ User cancellation handled correctly
- ✅ Background/foreground transitions work

### Performance Tests
- Memory usage: ~150MB during scan
- Battery usage: ~8%/hour during active scanning
- Scan completion time: 45 seconds average

### Issues Found
- None / [List any issues discovered]

### Recommendations
- [Any recommendations for improvements]
```

## Known Limitations

1. **Simulator Testing**: Cannot test actual scanning functionality in simulator
2. **macOS Testing**: RoomPlan is iOS-only, no macOS support
3. **Lighting Requirements**: Requires adequate lighting for best results
4. **Room Size Limits**: Very large rooms (>10m) may have accuracy issues
5. **Surface Requirements**: Plain walls work better than textured/patterned walls

## Reporting Issues

When reporting issues, please include:
- Device model and iOS version
- Flutter/Dart version
- Room size and characteristics
- Lighting conditions
- Complete error messages and stack traces
- Steps to reproduce
- Expected vs actual behavior

Submit issues at: https://github.com/Barba2k2/flutter_roomplan/issues