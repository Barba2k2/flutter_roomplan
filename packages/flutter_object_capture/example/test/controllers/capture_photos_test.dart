import 'package:flutter/services.dart';
import 'package:flutter_object_capture_example/controllers/reconstruct_controller.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;
  late ReconstructController controller;
  late List<String> created;

  setUp(() {
    native = FakeNative()..install();
    created = [];
    controller = ReconstructController(
      documentsPath: () async => '/docs',
      createDirectory: (path) async => created.add(path),
    );
  });

  tearDown(() {
    controller.dispose();
    native.uninstall();
  });

  test('success creates a fresh folder and uses the captured one', () async {
    await controller.capturePhotos();
    expect(created.single, startsWith('/docs/captures/capture-'));
    final sent = native.calls.singleWhere((c) => c.method == 'captureImages');
    expect((sent.arguments as Map)['imagesDirectory'], created.single);
    expect(controller.form.imagesDirectory, '/captured');
    expect(controller.errorMessage, isNull);
    expect(controller.isCapturing, isFalse);
  });

  test('two captures use two different folders', () async {
    await controller.capturePhotos();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await controller.capturePhotos();
    expect(created.toSet(), hasLength(2));
  });

  test('unsupported device shows the message, no capture call', () async {
    native.guidedSupported = false;
    await controller.capturePhotos();
    expect(controller.errorMessage, AppStrings.guidedUnsupported);
    expect(native.captureCalls, 0);
    expect(created, isEmpty);
    expect(controller.form.imagesDirectory, isNull);
    expect(controller.isCapturing, isFalse);
  });

  test('user cancel shows the cancel message and keeps the old folder',
      () async {
    controller.setImagesDirectory('/old');
    native.captureError = PlatformException(code: 'cancelled');
    await controller.capturePhotos();
    expect(controller.errorMessage, AppStrings.captureCancelled);
    expect(controller.form.imagesDirectory, '/old');
    expect(controller.isCapturing, isFalse);
  });

  test('directory not empty is reported', () async {
    native.captureError = PlatformException(code: 'directory_not_empty');
    await controller.capturePhotos();
    expect(controller.errorMessage, AppStrings.errorDirectoryNotEmpty);
    expect(controller.form.imagesDirectory, isNull);
  });

  test('other native errors get their own message', () async {
    final cases = {
      'sensor_failed': AppStrings.errorSensor,
      'tracking_failed': AppStrings.errorTracking,
      'insufficient_storage': AppStrings.errorStorage,
    };
    for (final entry in cases.entries) {
      native.captureError = PlatformException(code: entry.key);
      await controller.capturePhotos();
      expect(
        controller.errorMessage,
        startsWith(entry.value),
        reason: entry.key,
      );
    }
  });

  test('malformed native result is an error, folder untouched', () async {
    native.captureResult = 'oops';
    await controller.capturePhotos();
    expect(controller.errorMessage, isNotNull);
    expect(controller.form.imagesDirectory, isNull);
  });

  test('failure creating the folder is reported and capture not called',
      () async {
    controller.dispose();
    controller = ReconstructController(
      documentsPath: () async => '/docs',
      createDirectory: (path) async => throw StateError('disk full'),
    );
    await controller.capturePhotos();
    expect(controller.errorMessage, contains('disk full'));
    expect(native.captureCalls, 0);
  });

  test('ignored while a capture is already open', () async {
    final first = controller.capturePhotos();
    await controller.capturePhotos();
    await first;
    expect(native.captureCalls, 1);
  });

  test('a captured folder feeds Start', () async {
    await controller.capturePhotos();
    final running = controller.start();
    await pumpEventQueue();
    final sent =
        native.calls.singleWhere((c) => c.method == 'startReconstruction');
    expect((sent.arguments as Map)['imagesDirectory'], '/captured');
    native.nativeError('cancelled');
    await running;
  });
}
