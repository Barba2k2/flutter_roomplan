import 'package:flutter/services.dart';
import 'package:flutter_object_capture_example/controllers/reconstruct_controller.dart';
import 'package:flutter_object_capture_example/models/reconstruct_phase.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;
  late ReconstructController controller;

  setUp(() {
    native = FakeNative()..install();
    controller = ReconstructController(documentsPath: () async => '/docs');
  });

  tearDown(() {
    controller.dispose();
    native.uninstall();
  });

  late Future<void> running;

  Future<void> begin() async {
    controller.setImagesDirectory('/photos');
    running = controller.start();
    await pumpEventQueue();
  }

  test('happy path: progress, issues, notices, completed', () async {
    await begin();
    expect(controller.phase, ReconstructPhase.running);
    expect(native.calls.last.arguments['outputPath'], '/docs/model.usdz');

    native.progress(0.4, seconds: 90);
    native.sampleIssue(3, reason: 'blurry');
    native.notice('automaticDownsampling');
    await pumpEventQueue();
    expect(controller.progress, 0.4);
    expect(controller.remaining, const Duration(seconds: 90));
    expect(controller.events, hasLength(2));

    native.completed('/docs/model.usdz', 2048);
    await running;
    expect(controller.phase, ReconstructPhase.completed);
    expect(controller.progress, 1);
    expect(controller.result?.path, '/docs/model.usdz');
    expect(controller.result?.fileSizeBytes, 2048);
    expect(controller.errorMessage, isNull);
  });

  test('adds .usdz only when missing', () async {
    controller.setOutputName('chair.usdz');
    await begin();
    expect(native.calls.last.arguments['outputPath'], '/docs/chair.usdz');
    native.completed('/docs/chair.usdz', 1);
    await running;
  });

  test('start without folder does not call native', () async {
    await controller.start();
    expect(controller.phase, ReconstructPhase.failed);
    expect(controller.errorMessage, AppStrings.errorNoFolder);
    expect(native.calls, isEmpty);
  });

  test('empty name and name with slash are rejected before native', () async {
    controller.setImagesDirectory('/photos');
    controller.setOutputName('   ');
    await controller.start();
    expect(controller.errorMessage, AppStrings.errorNoName);
    controller.setOutputName('a/b');
    await controller.start();
    expect(controller.errorMessage, AppStrings.errorBadName);
    expect(native.calls, isEmpty);
  });

  test('regression: starting twice calls native once', () async {
    await begin();
    await controller.start();
    await pumpEventQueue();
    expect(native.startCalls, 1);
    native.completed('/docs/model.usdz', 1);
    await running;
  });

  test('cancel when idle does nothing', () async {
    await controller.cancel();
    expect(native.calls, isEmpty);
    expect(controller.phase, ReconstructPhase.idle);
  });

  test('cancel while running ends as cancelled', () async {
    await begin();
    final cancelling = controller.cancel();
    await pumpEventQueue();
    expect(native.cancelCalls, 1);
    native.nativeError('cancelled');
    await cancelling;
    await running;
    expect(controller.phase, ReconstructPhase.cancelled);
    expect(controller.errorMessage, AppStrings.errorCancelled);
  });

  group('every exception type shows its own message', () {
    final cases = <String, String>{
      'not_supported': AppStrings.errorNotSupported,
      'invalid_images': AppStrings.errorInvalidImages,
      'invalid_output': AppStrings.errorInvalidOutput,
      'insufficient_storage': AppStrings.errorStorage,
      'session_in_progress': AppStrings.errorInProgress,
      'reconstruction_failed': AppStrings.errorFailed,
      'something_else': AppStrings.errorNative,
    };
    cases.forEach((code, expected) {
      test('$code as stream error', () async {
        await begin();
        native.nativeError(code, message: 'details');
        await running;
        expect(controller.phase, ReconstructPhase.failed);
        expect(controller.errorMessage, contains(expected));
      });
    });

    test('error thrown by startReconstruction', () async {
      native.startError = PlatformException(code: 'invalid_images');
      await begin();
      await running;
      expect(controller.phase, ReconstructPhase.failed);
      expect(controller.errorMessage, contains(AppStrings.errorInvalidImages));
    });

    test('malformed event payload', () async {
      await begin();
      native.sink?.success({'type': 'nonsense'});
      await running;
      expect(controller.errorMessage, contains(AppStrings.errorPayload));
    });
  });

  test('can start again after a failure', () async {
    await begin();
    native.nativeError('reconstruction_failed', message: 'x');
    await running;
    running = controller.start();
    await pumpEventQueue();
    expect(controller.phase, ReconstructPhase.running);
    expect(controller.errorMessage, isNull);
    native.completed('/docs/model.usdz', 1);
    await running;
    expect(controller.phase, ReconstructPhase.completed);
  });
}
