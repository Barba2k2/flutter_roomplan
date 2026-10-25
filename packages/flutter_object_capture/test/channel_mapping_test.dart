import 'package:flutter/services.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_object_capture/src/services/object_capture_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('flutter_object_capture/method_channel');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockMethod(Future<Object?> Function(MethodCall call)? handler) {
    messenger.setMockMethodCallHandler(methodChannel, handler);
  }

  tearDown(() => mockMethod(null));

  group('PlatformException code mapping', () {
    final cases = <String, Matcher>{
      'invalid_images': isA<InvalidImagesDirectoryException>(),
      'invalid_output': isA<InvalidOutputPathException>(),
      'insufficient_storage': isA<InsufficientStorageException>(),
      'session_in_progress': isA<ReconstructionInProgressException>(),
      'cancelled': isA<ReconstructionCancelledException>(),
      'reconstruction_failed': isA<ReconstructionFailedException>(),
      'not_supported': isA<ObjectCaptureNotSupportedException>(),
      'something_new': isA<NativeChannelException>(),
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

    test('insufficient_storage carries requiredBytes from details', () {
      final exception = ObjectCaptureChannel.mapPlatformException(
        PlatformException(
          code: 'insufficient_storage',
          details: {'requiredBytes': 123456},
        ),
      ) as InsufficientStorageException;
      expect(exception.requiredBytes, 123456);
    });

    test('insufficient_storage without details has null requiredBytes', () {
      final exception = ObjectCaptureChannel.mapPlatformException(
        PlatformException(code: 'insufficient_storage'),
      ) as InsufficientStorageException;
      expect(exception.requiredBytes, isNull);
    });

    test('reconstruction_failed keeps the native message', () {
      final exception = ObjectCaptureChannel.mapPlatformException(
        PlatformException(code: 'reconstruction_failed', message: 'gpu lost'),
      );
      expect(exception.message, contains('gpu lost'));
    });

    test('unknown code keeps code and message', () {
      final exception = ObjectCaptureChannel.mapPlatformException(
        PlatformException(code: 'weird', message: 'text'),
      );
      expect(exception.message, allOf(contains('weird'), contains('text')));
    });
  });

  group('isSupported', () {
    test('returns the native value', () async {
      mockMethod((call) async => call.method == 'isSupported' ? true : null);
      expect(await ObjectCaptureChannel().isSupported(), isTrue);
    });

    test('false when native answers false or null', () async {
      mockMethod((call) async => false);
      expect(await ObjectCaptureChannel().isSupported(), isFalse);
      mockMethod((call) async => null);
      expect(await ObjectCaptureChannel().isSupported(), isFalse);
    });

    test('false when the channel throws', () async {
      mockMethod((call) async => throw PlatformException(code: 'boom'));
      expect(await ObjectCaptureChannel().isSupported(), isFalse);
    });

    test('false on MissingPluginException (no handler registered)', () async {
      mockMethod(null);
      expect(await ObjectCaptureChannel().isSupported(), isFalse);
    });
  });

  group('getLimits', () {
    test('parses the native map', () async {
      mockMethod((call) async => {'maxImages': 250, 'maxImageDimension': 4096});
      expect(
        await ObjectCaptureChannel().getLimits(),
        const ObjectCaptureLimits(maxImages: 250, maxImageDimension: 4096),
      );
    });

    test('malformed result throws PayloadParsingException', () async {
      for (final result in <Object?>[
        null,
        'x',
        {'maxImages': 1},
        {'maxImages': 'a', 'maxImageDimension': 2}
      ]) {
        mockMethod((call) async => result);
        await expectLater(
          ObjectCaptureChannel().getLimits(),
          throwsA(isA<PayloadParsingException>()),
          reason: '$result',
        );
      }
    });

    test('PlatformException is mapped', () async {
      mockMethod(
          (call) async => throw PlatformException(code: 'not_supported'));
      await expectLater(
        ObjectCaptureChannel().getLimits(),
        throwsA(isA<ObjectCaptureNotSupportedException>()),
      );
    });

    test('MissingPluginException becomes not supported', () async {
      mockMethod(null);
      await expectLater(
        ObjectCaptureChannel().getLimits(),
        throwsA(isA<ObjectCaptureNotSupportedException>()),
      );
    });
  });

  group('startReconstruction / cancelReconstruction', () {
    test('forward the arguments to native', () async {
      MethodCall? received;
      mockMethod((call) async {
        received = call;
        return null;
      });
      await ObjectCaptureChannel().startReconstruction({'a': 1});
      expect(received?.method, 'startReconstruction');
      expect(received?.arguments, {'a': 1});
      await ObjectCaptureChannel().cancelReconstruction();
      expect(received?.method, 'cancelReconstruction');
    });

    test('PlatformException from start is mapped', () async {
      mockMethod(
          (call) async => throw PlatformException(code: 'invalid_images'));
      await expectLater(
        ObjectCaptureChannel().startReconstruction({}),
        throwsA(isA<InvalidImagesDirectoryException>()),
      );
    });

    test('PlatformException from cancel is mapped', () async {
      mockMethod((call) async => throw PlatformException(code: 'weird'));
      await expectLater(
        ObjectCaptureChannel().cancelReconstruction(),
        throwsA(isA<NativeChannelException>()),
      );
    });
  });
}
