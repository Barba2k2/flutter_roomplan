import 'package:flutter/services.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_object_capture/method_channel');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isSupported':
          return true;
        case 'captureObject':
          return <String, Object?>{
            'imagesFolderPath': '/tmp/images',
            'captureCount': 42,
            'startedAt': '2024-01-01T00:00:00.000Z',
            'completedAt': '2024-01-01T00:05:00.000Z',
          };
        case 'reconstruct':
          return <String, Object?>{
            'modelPath': '/tmp/model.usdz',
            'detailLevel': 'medium',
            'processingTimeMs': 12000,
          };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isSupported returns the value reported by the platform', () async {
    expect(await FlutterObjectCapture.isSupported(), isTrue);
  });

  test('captureObject decodes a successful payload', () async {
    final result = await FlutterObjectCapture.captureObject();
    expect(result.imagesFolderPath, '/tmp/images');
    expect(result.captureCount, 42);
    expect(result.duration, const Duration(minutes: 5));
  });

  test('reconstruct decodes a successful payload', () async {
    final result = await FlutterObjectCapture.reconstruct(
      imagesPath: '/tmp/images',
    );
    expect(result.modelPath, '/tmp/model.usdz');
    expect(result.detailLevel, DetailLevel.medium);
    expect(result.processingTime, const Duration(seconds: 12));
  });

  test('captureObject maps unsupported errors', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'unsupported',
        message: 'No A14 chip detected.',
      );
    });

    expect(
      () => FlutterObjectCapture.captureObject(),
      throwsA(isA<ObjectCaptureUnsupportedException>()),
    );
  });
}
