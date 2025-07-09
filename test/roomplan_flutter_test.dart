import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('roomplan_flutter/method_channel');
  MethodCall? receivedCall;

  setUp(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      receivedCall = methodCall;
      switch (methodCall.method) {
        case 'isRoomPlanSupported':
          return true;
        case 'startRoomCapture':
          return null;
        case 'stopRoomCapture':
          return null; // Mock the stop call
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isSupported returns true when platform supports it', () async {
    final scanner = RoomPlanScanner();
    final result = await scanner.isSupported();

    expect(result, isTrue);
    expect(receivedCall?.method, 'isRoomPlanSupported');
    scanner.dispose();
  });

  test('startScanning and finishScanning returns a parsed result', () async {
    final scanner = RoomPlanScanner();
    // We simulate this by invoking the method on the channel manually.
    final futureResult = scanner.finishScanning();

    await TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'roomplan_flutter/method_channel',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall(
          'onScanResult',
          {
            'result': '''
            {
              "walls": [],
              "objects": [],
              "floors": [
                {
                  "dimensions": [1.0, 2.0, 3.0]
                }
              ]
            }
            '''
          },
        ),
      ),
      (ByteData? data) {},
    );

    final result = await futureResult;

    // Assertions
    expect(result, isA<ScanResult>());
    expect(result, isNotNull);
    expect(result!.room, isNotNull);
    expect(result.room.dimensions, isNotNull);

    // Note: fromList uses [length, width, height]
    expect(result.room.dimensions!.length, 1.0);
    expect(result.room.dimensions!.width, 2.0);
    expect(result.room.dimensions!.height, 3.0);

    scanner.dispose();
  });
}
