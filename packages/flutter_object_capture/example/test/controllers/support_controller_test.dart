import 'package:flutter/services.dart';
import 'package:flutter_object_capture_example/controllers/support_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;
  late SupportController controller;

  setUp(() {
    native = FakeNative()..install();
    controller = SupportController();
  });

  tearDown(() {
    controller.dispose();
    native.uninstall();
  });

  test('supported device exposes limits', () async {
    await controller.load();
    expect(controller.info?.supported, isTrue);
    expect(controller.info?.limits?.maxImages, 100);
    expect(controller.info?.limits?.maxImageDimension, 4096);
    expect(controller.errorMessage, isNull);
  });

  test('unsupported device skips getLimits', () async {
    native.supported = false;
    await controller.load();
    expect(controller.info?.supported, isFalse);
    expect(controller.info?.limits, isNull);
    expect(native.calls.map((c) => c.method), ['isSupported']);
  });

  test('getLimits failure becomes a message', () async {
    native.limitsError = PlatformException(code: 'reconstruction_failed');
    await controller.load();
    expect(controller.info, isNull);
    expect(controller.errorMessage, isNotNull);
    expect(controller.isLoading, isFalse);
  });

  test('loading twice at once asks the device once', () async {
    final first = controller.load();
    final second = controller.load();
    await Future.wait([first, second]);
    expect(native.calls.where((c) => c.method == 'isSupported'), hasLength(1));
  });
}
