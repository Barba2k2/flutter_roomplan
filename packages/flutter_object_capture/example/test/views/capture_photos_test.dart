import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_object_capture_example/controllers/reconstruct_controller.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_object_capture_example/views/reconstruct_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;
  late ReconstructController controller;

  setUp(() {
    native = FakeNative()..install();
    controller = ReconstructController(
      documentsPath: () async => '/docs',
      createDirectory: (path) async {},
    );
  });

  tearDown(() => native.uninstall());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ReconstructPage(controller: controller)),
    );
  }

  Finder button(String label) => find.ancestor(
        of: find.text(label),
        matching: find.bySubtype<ButtonStyleButton>(),
      );

  testWidgets('Capture photos fills the folder shown on the page', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(button(AppStrings.capturePhotos));
    await settle(tester);
    expect(find.text('/captured'), findsOneWidget);
    expect(find.text(AppStrings.changeFolder), findsOneWidget);
  });

  testWidgets('unsupported device hides the capture button', (tester) async {
    native.guidedSupported = false;
    await pumpPage(tester);
    await settle(tester);
    expect(find.text(AppStrings.capturePhotos), findsNothing);
    expect(find.text(AppStrings.chooseFolder), findsOneWidget);
    expect(find.text(AppStrings.noFolderChosen), findsOneWidget);
  });

  testWidgets('supported device shows the capture button', (tester) async {
    await pumpPage(tester);
    await settle(tester);
    expect(find.text(AppStrings.capturePhotos), findsOneWidget);
  });

  testWidgets('cancel shows the cancelled message', (tester) async {
    native.captureError = PlatformException(code: 'cancelled');
    await pumpPage(tester);
    await tester.tap(button(AppStrings.capturePhotos));
    await settle(tester);
    expect(find.text(AppStrings.captureCancelled), findsOneWidget);
  });

  testWidgets('directory not empty shows its message', (tester) async {
    native.captureError = PlatformException(code: 'directory_not_empty');
    await pumpPage(tester);
    await tester.tap(button(AppStrings.capturePhotos));
    await settle(tester);
    expect(find.text(AppStrings.errorDirectoryNotEmpty), findsOneWidget);
  });
}
