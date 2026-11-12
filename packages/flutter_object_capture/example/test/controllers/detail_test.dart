import 'package:flutter/services.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_object_capture_example/controllers/reconstruct_controller.dart';
import 'package:flutter_object_capture_example/models/reconstruct_phase.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;

  setUp(() => native = FakeNative()..install());
  tearDown(() => native.uninstall());

  ReconstructController build(List<ObjectDetail> details) {
    return ReconstructController(
      documentsPath: () async => '/docs',
      supportedDetails: details,
    );
  }

  test('one supported detail hides the selector', () {
    final controller = build(const [ObjectDetail.reduced]);
    addTearDown(controller.dispose);
    expect(controller.showDetailSelector, isFalse);
  });

  test('several supported details show the selector', () {
    final controller = build(ObjectDetail.values);
    addTearDown(controller.dispose);
    expect(controller.showDetailSelector, isTrue);
    expect(controller.form.detail, ObjectDetail.reduced);
  });

  test('setDetail changes the form and notifies', () {
    final controller = build(ObjectDetail.values);
    addTearDown(controller.dispose);
    var notified = 0;
    controller.addListener(() => notified++);
    controller.setDetail(ObjectDetail.full);
    expect(controller.form.detail, ObjectDetail.full);
    expect(notified, 1);
  });

  test('setDetail ignores a level the platform lacks', () {
    final controller = build(const [ObjectDetail.reduced]);
    addTearDown(controller.dispose);
    controller.setDetail(ObjectDetail.raw);
    expect(controller.form.detail, ObjectDetail.reduced);
  });

  test('the chosen detail reaches native', () async {
    final controller = build(ObjectDetail.values);
    addTearDown(controller.dispose);
    controller.setImagesDirectory('/photos');
    controller.setDetail(ObjectDetail.medium);
    final running = controller.start();
    await pumpEventQueue();
    expect(native.calls.last.arguments['detail'], 'medium');
    native.completed('/docs/model.usdz', 1);
    await running;
  });

  test('unsupported_detail from native shows its message', () async {
    final controller = build(ObjectDetail.values);
    addTearDown(controller.dispose);
    native.startError = PlatformException(code: 'unsupported_detail');
    controller.setImagesDirectory('/photos');
    controller.setDetail(ObjectDetail.raw);
    await controller.start();
    expect(controller.phase, ReconstructPhase.failed);
    expect(controller.errorMessage, AppStrings.errorUnsupportedDetail);
  });
}
