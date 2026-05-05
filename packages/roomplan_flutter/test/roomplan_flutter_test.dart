import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('roomplan_flutter/method_channel');

  const mockScanResultJson = '''
  {
    "dimensions": {"x": 5.0, "y": 2.5, "z": 4.0},
    "walls": [], "objects": [], "doors": [], "windows": [],
    "metadata": { "session_duration": 120 },
    "confidence": { "overall": 0.8 }
  }
  ''';

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('RoomPlanScanner Tests', () {
    test('isSupported returns false on non-iOS platforms', () async {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSupported') {
          return false;
        }
        return null;
      });

      final isSupported = await RoomPlanScanner.isSupported();
      expect(isSupported, isFalse);
    });

    test('startScanning returns a non-null result on success', () async {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startRoomCapture') {
          return mockScanResultJson;
        }
        return null;
      });

      final scanner = RoomPlanScanner();
      final result = await scanner.startScanning();

      expect(result, isNotNull);
      expect(result, isA<ScanResult>());
      scanner.dispose();
    });

    test('startScanning throws ScanCancelledException when user cancels',
        () async {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'startRoomCapture') {
            throw PlatformException(code: 'CANCELED');
          }
          return null;
        },
      );

      final scanner = RoomPlanScanner();
      expect(
        () => scanner.startScanning(),
        throwsA(isA<ScanCancelledException>()),
      );
      scanner.dispose();
    });

    test(
        'startScanning throws RoomPlanPermissionsException when permission denied',
        () async {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'startRoomCapture') {
            throw PlatformException(code: 'camera_permission_denied');
          }
          return null;
        },
      );

      final scanner = RoomPlanScanner();
      expect(
        () => scanner.startScanning(),
        throwsA(isA<RoomPlanPermissionsException>()),
      );
      scanner.dispose();
    });

    test('stopScanning calls platform method', () async {
      bool stopCalled = false;
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'stopRoomCapture') {
          stopCalled = true;
          return null;
        }
        return null;
      });

      final scanner = RoomPlanScanner();
      await scanner.stopScanning();

      expect(stopCalled, isTrue);
      scanner.dispose();
    });
  });

  group('Model Tests', () {
    test('ScanResult can be parsed from JSON', () async {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startRoomCapture') {
          return mockScanResultJson;
        }
        return null;
      });

      final scanner = RoomPlanScanner();
      final result = await scanner.startScanning();

      expect(result, isNotNull);
      // Add a null check for dimensions
      expect(result!.room.dimensions, isNotNull);
      expect(result.room.dimensions!.length, equals(5.0));
      expect(result.room.dimensions!.width, equals(4.0));
      expect(result.room.dimensions!.height, equals(2.5));
      expect(result.confidence.overall, equals(0.8));

      scanner.dispose();
    });
  });
}
