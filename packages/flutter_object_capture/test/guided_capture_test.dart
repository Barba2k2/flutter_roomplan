import 'package:flutter/services.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_object_capture/src/services/object_capture_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('flutter_object_capture/method_channel');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void mockMethod(Future<Object?> Function(MethodCall call) handler) {
    calls = [];
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(methodChannel, null));

  group('error code mapping', () {
    final cases = <String, Matcher>{
      'directory_not_empty': isA<DirectoryNotEmptyException>(),
      'sensor_failed': isA<CaptureSensorFailedException>(),
      'tracking_failed': isA<CaptureTrackingFailedException>(),
      'capture_failed': isA<CaptureFailedException>(),
      'cancelled': isA<ReconstructionCancelledException>(),
      'insufficient_storage': isA<InsufficientStorageException>(),
    };
    cases.forEach((code, matcher) {
      test('$code maps to the right exception', () {
        expect(
          ObjectCaptureChannel.mapPlatformException(
            PlatformException(code: code, message: 'native text'),
          ),
          matcher,
        );
      });
    });

    test('capture_failed keeps the native message', () {
      final exception = ObjectCaptureChannel.mapPlatformException(
        PlatformException(code: 'capture_failed', message: 'camera lost'),
      );
      expect(exception.message, contains('camera lost'));
    });
  });

  group('isGuidedCaptureSupported', () {
    test('returns the native value', () async {
      mockMethod((call) async => true);
      expect(await ObjectCaptureProcessor.isGuidedCaptureSupported(), isTrue);
      expect(calls.single.method, 'isGuidedCaptureSupported');
    });

    test('false on native false, error or missing plugin', () async {
      mockMethod((call) async => false);
      expect(await ObjectCaptureProcessor.isGuidedCaptureSupported(), isFalse);
      mockMethod((call) async => throw PlatformException(code: 'boom'));
      expect(await ObjectCaptureProcessor.isGuidedCaptureSupported(), isFalse);
      messenger.setMockMethodCallHandler(methodChannel, null);
      expect(await ObjectCaptureProcessor.isGuidedCaptureSupported(), isFalse);
    });
  });

  group('captureImages', () {
    final processor = ObjectCaptureProcessor();

    test('sends the argument map and parses the result', () async {
      mockMethod(
        (call) async => {
          'imagesDirectory': '/docs/images',
          'checkpointDirectory': '/docs/checkpoint',
          'imageCount': 42,
        },
      );
      final result = await processor.captureImages(
        imagesDirectory: '/docs/images',
        checkpointDirectory: '/docs/checkpoint',
        isOverCaptureEnabled: true,
        areaMode: true,
      );
      expect(calls.single.method, 'captureImages');
      expect(calls.single.arguments, {
        'imagesDirectory': '/docs/images',
        'checkpointDirectory': '/docs/checkpoint',
        'isOverCaptureEnabled': true,
        'areaMode': true,
      });
      expect(
        result,
        const ObjectCaptureSessionResult(
          imagesDirectory: '/docs/images',
          checkpointDirectory: '/docs/checkpoint',
          imageCount: 42,
        ),
      );
    });

    test('defaults flags to false and omits a missing checkpoint', () async {
      mockMethod(
        (call) async => {'imagesDirectory': '/docs/images', 'imageCount': 3},
      );
      final result = await processor.captureImages(
        imagesDirectory: '/docs/images',
      );
      expect(calls.single.arguments, {
        'imagesDirectory': '/docs/images',
        'isOverCaptureEnabled': false,
        'areaMode': false,
      });
      expect(result.checkpointDirectory, isNull);
    });

    test('empty images directory throws before calling native', () {
      mockMethod((call) async => null);
      expect(
        () => processor.captureImages(imagesDirectory: '  '),
        throwsA(isA<InvalidImagesDirectoryException>()),
      );
      expect(calls, isEmpty);
    });

    final nativeErrors = <String, Matcher>{
      'cancelled': isA<ReconstructionCancelledException>(),
      'not_supported': isA<ObjectCaptureNotSupportedException>(),
      'directory_not_empty': isA<DirectoryNotEmptyException>(),
      'insufficient_storage': isA<InsufficientStorageException>(),
      'sensor_failed': isA<CaptureSensorFailedException>(),
      'tracking_failed': isA<CaptureTrackingFailedException>(),
      'session_in_progress': isA<ReconstructionInProgressException>(),
    };
    nativeErrors.forEach((code, matcher) {
      test('native $code throws the mapped exception', () {
        mockMethod((call) async => throw PlatformException(code: code));
        expect(
          processor.captureImages(imagesDirectory: '/docs/images'),
          throwsA(matcher),
        );
      });
    });

    test('missing plugin throws not supported', () {
      messenger.setMockMethodCallHandler(methodChannel, null);
      expect(
        processor.captureImages(imagesDirectory: '/docs/images'),
        throwsA(isA<ObjectCaptureNotSupportedException>()),
      );
    });

    final malformed = <String, Object?>{
      'null': null,
      'not a map': 'oops',
      'missing directory': {'imageCount': 1},
      'missing count': {'imagesDirectory': '/a'},
      'wrong count type': {'imagesDirectory': '/a', 'imageCount': '1'},
      'wrong checkpoint type': {
        'imagesDirectory': '/a',
        'imageCount': 1,
        'checkpointDirectory': 5,
      },
    };
    malformed.forEach((name, payload) {
      test('malformed result ($name) throws PayloadParsingException', () {
        mockMethod((call) async => payload);
        expect(
          processor.captureImages(imagesDirectory: '/docs/images'),
          throwsA(isA<PayloadParsingException>()),
        );
      });
    });
  });

  group('ObjectCaptureSessionResult', () {
    test('value equality', () {
      const a =
          ObjectCaptureSessionResult(imagesDirectory: '/a', imageCount: 1);
      const b =
          ObjectCaptureSessionResult(imagesDirectory: '/a', imageCount: 1);
      const c =
          ObjectCaptureSessionResult(imagesDirectory: '/a', imageCount: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
