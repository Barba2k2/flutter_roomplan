import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('flutter_object_capture/method_channel');
  const eventChannel = EventChannel('flutter_object_capture/event_channel');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late MockStreamHandlerEventSink? sink;
  late Object? startResult;
  late int eventListens;
  late int eventCancels;

  setUp(() {
    calls = [];
    sink = null;
    startResult = null;
    eventListens = 0;
    eventCancels = 0;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      calls.add(call);
      if (call.method == 'startReconstruction' &&
          startResult is PlatformException) {
        throw startResult! as PlatformException;
      }
      return null;
    });
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          eventListens++;
          sink = events;
        },
        onCancel: (arguments) {
          eventCancels++;
          sink = null;
        },
      ),
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockStreamHandler(eventChannel, null);
  });

  Stream<ReconstructionEvent> start(
    ObjectCaptureProcessor processor, {
    ObjectCaptureConfiguration configuration =
        const ObjectCaptureConfiguration(),
  }) {
    return processor.reconstruct(
      imagesDirectory: '/photos',
      outputPath: '/out/model.usdz',
      configuration: configuration,
    );
  }

  Iterable<MethodCall> callsNamed(String name) =>
      calls.where((c) => c.method == name);

  group('static / simple calls', () {
    test('isSupported is false off-device (no plugin handler)', () async {
      messenger.setMockMethodCallHandler(methodChannel, null);
      expect(await ObjectCaptureProcessor.isSupported(), isFalse);
    });

    test('isSupported true when native says so', () async {
      messenger.setMockMethodCallHandler(methodChannel, (call) async => true);
      expect(await ObjectCaptureProcessor.isSupported(), isTrue);
    });

    test('getLimits returns native limits', () async {
      messenger.setMockMethodCallHandler(
        methodChannel,
        (call) async => {'maxImages': 100, 'maxImageDimension': 2048},
      );
      final processor = ObjectCaptureProcessor();
      expect(
        await processor.getLimits(),
        const ObjectCaptureLimits(maxImages: 100, maxImageDimension: 2048),
      );
      processor.dispose();
    });
  });

  group('argument validation', () {
    test('empty imagesDirectory throws before touching the channel', () {
      final processor = ObjectCaptureProcessor();
      for (final directory in ['', '   ']) {
        expect(
          () => processor.reconstruct(
            imagesDirectory: directory,
            outputPath: '/out/model.usdz',
          ),
          throwsA(isA<InvalidImagesDirectoryException>()),
        );
      }
      expect(calls, isEmpty);
      expect(eventListens, 0);
      processor.dispose();
    });

    test('bad outputPath throws before touching the channel', () {
      final processor = ObjectCaptureProcessor();
      expect(
        () => processor.reconstruct(
          imagesDirectory: '/photos',
          outputPath: '/out/model.obj',
        ),
        throwsA(isA<InvalidOutputPathException>()),
      );
      expect(calls, isEmpty);
      expect(eventListens, 0);
      processor.dispose();
    });

    test('a validation failure does not occupy the single job slot', () async {
      final processor = ObjectCaptureProcessor();
      expect(
        () => processor.reconstruct(imagesDirectory: '', outputPath: '/o.usdz'),
        throwsA(isA<InvalidImagesDirectoryException>()),
      );
      final subscription = start(processor).listen((_) {});
      await pumpEventQueue();
      expect(callsNamed('startReconstruction'), hasLength(1));
      await subscription.cancel();
      processor.dispose();
    });
  });

  group('reconstruct', () {
    test('sends every config field and both paths to native', () async {
      final processor = ObjectCaptureProcessor();
      final subscription = start(
        processor,
        configuration: const ObjectCaptureConfiguration(
          featureSensitivity: FeatureSensitivity.high,
          sampleOrdering: SampleOrdering.sequential,
        ),
      ).listen((_) {});
      await pumpEventQueue();
      expect(callsNamed('startReconstruction'), hasLength(1));
      expect(callsNamed('startReconstruction').single.arguments, {
        'imagesDirectory': '/photos',
        'outputPath': '/out/model.usdz',
        'featureSensitivity': 'high',
        'sampleOrdering': 'sequential',
      });
      await subscription.cancel();
      processor.dispose();
    });

    test('default configuration is sent as normal / unordered', () async {
      final processor = ObjectCaptureProcessor();
      final subscription = start(processor).listen((_) {});
      await pumpEventQueue();
      final arguments =
          callsNamed('startReconstruction').single.arguments as Map;
      expect(arguments['featureSensitivity'], 'normal');
      expect(arguments['sampleOrdering'], 'unordered');
      await subscription.cancel();
      processor.dispose();
    });

    test('nothing reaches native until the stream is listened to', () async {
      final processor = ObjectCaptureProcessor();
      start(processor);
      await pumpEventQueue();
      expect(calls, isEmpty);
      expect(eventListens, 0);
      processor.dispose();
    });

    test('forwards events in order and closes after completed', () async {
      final processor = ObjectCaptureProcessor();
      final events = <ReconstructionEvent>[];
      final done = Completer<void>();
      start(processor).listen(events.add, onDone: done.complete);
      await pumpEventQueue();
      sink!.success({'type': 'progress', 'fraction': 0.5});
      sink!.success({'type': 'notice', 'notice': 'inputComplete'});
      sink!.success({'type': 'sampleIssue', 'sampleId': 2, 'reason': 'blurry'});
      sink!.success({
        'type': 'completed',
        'modelPath': '/out/model.usdz',
        'fileSizeBytes': 10,
      });
      await done.future.timeout(const Duration(seconds: 2));
      expect(events, [
        const ReconstructionProgress(fraction: 0.5),
        const ReconstructionNotice(
            type: ReconstructionNoticeType.inputComplete),
        const ReconstructionSampleIssue(sampleId: 2, reason: 'blurry'),
        const ReconstructionCompleted(
            modelPath: '/out/model.usdz', fileSizeBytes: 10),
      ]);
      expect(callsNamed('cancelReconstruction'), isEmpty);
      await pumpEventQueue();
      expect(eventCancels, 1);
      processor.dispose();
    });

    test('a new job can start after completion', () async {
      final processor = ObjectCaptureProcessor();
      final first = Completer<void>();
      start(processor).listen((_) {}, onDone: first.complete);
      await pumpEventQueue();
      sink!.success(
          {'type': 'completed', 'modelPath': '/a.usdz', 'fileSizeBytes': 1});
      await first.future.timeout(const Duration(seconds: 2));
      await pumpEventQueue();

      final second = start(processor).listen((_) {});
      await pumpEventQueue();
      expect(callsNamed('startReconstruction'), hasLength(2));
      await second.cancel();
      processor.dispose();
    });
  });

  group('single job guard', () {
    test('second reconstruct while one is active throws', () async {
      final processor = ObjectCaptureProcessor();
      final subscription = start(processor).listen((_) {});
      expect(
        () => start(processor),
        throwsA(isA<ReconstructionInProgressException>()),
      );
      await pumpEventQueue();
      expect(callsNamed('startReconstruction'), hasLength(1));
      await subscription.cancel();
      processor.dispose();
    });

    test('the guard is released after the listener cancels', () async {
      final processor = ObjectCaptureProcessor();
      final subscription = start(processor).listen((_) {});
      await pumpEventQueue();
      await subscription.cancel();
      expect(() => start(processor), returnsNormally);
      processor.dispose();
    });

    test('the guard is released after an error', () async {
      final processor = ObjectCaptureProcessor();
      final done = Completer<void>();
      start(processor)
          .listen((_) {}, onError: (Object _) {}, onDone: done.complete);
      await pumpEventQueue();
      sink!.error(code: 'reconstruction_failed', message: 'x');
      await done.future.timeout(const Duration(seconds: 2));
      expect(() => start(processor), returnsNormally);
      processor.dispose();
    });

    test('cancel() on an unlistened stream releases the guard', () async {
      final processor = ObjectCaptureProcessor();
      start(processor);
      await processor.cancel();
      expect(() => start(processor), returnsNormally);
      expect(callsNamed('cancelReconstruction'), isEmpty);
      processor.dispose();
    });
  });

  group('cancellation', () {
    test('cancelling the subscription calls cancelReconstruction', () async {
      final processor = ObjectCaptureProcessor();
      final subscription = start(processor).listen((_) {});
      await pumpEventQueue();
      await subscription.cancel();
      await pumpEventQueue();
      expect(callsNamed('cancelReconstruction'), hasLength(1));
      expect(eventCancels, 1);
      processor.dispose();
    });

    test('cancel() asks native, and the native cancelled error ends the stream',
        () async {
      final processor = ObjectCaptureProcessor();
      final errors = <Object>[];
      final done = Completer<void>();
      start(processor)
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await pumpEventQueue();
      await processor.cancel();
      expect(callsNamed('cancelReconstruction'), hasLength(1));
      sink!.error(code: 'cancelled', message: 'cancelled');
      await done.future.timeout(const Duration(seconds: 2));
      expect(errors.single, isA<ReconstructionCancelledException>());
      processor.dispose();
    });

    test('cancel() with no active job is a no-op', () async {
      final processor = ObjectCaptureProcessor();
      await processor.cancel();
      expect(calls, isEmpty);
      processor.dispose();
    });

    test('cancel() is a no-op after completion', () async {
      final processor = ObjectCaptureProcessor();
      final done = Completer<void>();
      start(processor).listen((_) {}, onDone: done.complete);
      await pumpEventQueue();
      sink!.success(
          {'type': 'completed', 'modelPath': '/a.usdz', 'fileSizeBytes': 1});
      await done.future.timeout(const Duration(seconds: 2));
      await processor.cancel();
      expect(callsNamed('cancelReconstruction'), isEmpty);
      processor.dispose();
    });

    test('a failing native cancel on subscription cancel does not throw',
        () async {
      final processor = ObjectCaptureProcessor();
      final subscription = start(processor).listen((_) {});
      await pumpEventQueue();
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        throw PlatformException(code: 'weird');
      });
      await subscription.cancel();
      processor.dispose();
    });

    test('dispose cancels an active job', () async {
      final processor = ObjectCaptureProcessor();
      start(processor).listen((_) {});
      await pumpEventQueue();
      processor.dispose();
      await pumpEventQueue();
      expect(callsNamed('cancelReconstruction'), hasLength(1));
      expect(() => start(processor), returnsNormally);
    });
  });

  group('errors', () {
    test('every native error code arrives as the mapped stream error',
        () async {
      final expected = <String, Matcher>{
        'invalid_images': isA<InvalidImagesDirectoryException>(),
        'invalid_output': isA<InvalidOutputPathException>(),
        'insufficient_storage': isA<InsufficientStorageException>(),
        'session_in_progress': isA<ReconstructionInProgressException>(),
        'cancelled': isA<ReconstructionCancelledException>(),
        'reconstruction_failed': isA<ReconstructionFailedException>(),
        'not_supported': isA<ObjectCaptureNotSupportedException>(),
      };
      for (final entry in expected.entries) {
        final processor = ObjectCaptureProcessor();
        final errors = <Object>[];
        final done = Completer<void>();
        start(processor)
            .listen((_) {}, onError: errors.add, onDone: done.complete);
        await pumpEventQueue();
        sink!.error(code: entry.key, message: 'm');
        await done.future.timeout(const Duration(seconds: 2));
        expect(errors, hasLength(1), reason: entry.key);
        expect(errors.single, entry.value, reason: entry.key);
        processor.dispose();
      }
    });

    test(
        'a malformed event becomes a PayloadParsingException and ends the stream',
        () async {
      final processor = ObjectCaptureProcessor();
      final errors = <Object>[];
      final done = Completer<void>();
      start(processor)
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await pumpEventQueue();
      sink!.success({'type': 'bogus'});
      await done.future.timeout(const Duration(seconds: 2));
      expect(errors.single, isA<PayloadParsingException>());
      processor.dispose();
    });

    test(
        'startReconstruction failure arrives as a stream error and ends the stream',
        () async {
      startResult =
          PlatformException(code: 'invalid_images', message: 'bad dir');
      final processor = ObjectCaptureProcessor();
      final errors = <Object>[];
      final done = Completer<void>();
      start(processor)
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await done.future.timeout(const Duration(seconds: 2));
      expect(errors.single, isA<InvalidImagesDirectoryException>());
      expect(() => start(processor), returnsNormally);
      processor.dispose();
    });

    test(
        'session_in_progress from native (other processor) surfaces as the stream error',
        () async {
      startResult = PlatformException(code: 'session_in_progress');
      final processor = ObjectCaptureProcessor();
      final errors = <Object>[];
      final done = Completer<void>();
      start(processor)
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await done.future.timeout(const Duration(seconds: 2));
      expect(errors.single, isA<ReconstructionInProgressException>());
      processor.dispose();
    });

    test('events arriving after the stream ended are ignored', () async {
      final processor = ObjectCaptureProcessor();
      final events = <ReconstructionEvent>[];
      final done = Completer<void>();
      start(processor).listen(events.add, onDone: done.complete);
      await pumpEventQueue();
      final lateSink = sink!;
      lateSink.success(
          {'type': 'completed', 'modelPath': '/a.usdz', 'fileSizeBytes': 1});
      await done.future.timeout(const Duration(seconds: 2));
      lateSink.success({'type': 'progress', 'fraction': 0.1});
      await pumpEventQueue();
      expect(events, hasLength(1));
      processor.dispose();
    });
  });
}
