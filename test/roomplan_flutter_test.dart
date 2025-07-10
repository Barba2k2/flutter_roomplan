import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('roomplan_flutter/method_channel');

  const mockScanResultJson = '''
  {
    "dimensions": {"x": 5.0, "y": 4.0, "z": 2.5},
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
  });
}
