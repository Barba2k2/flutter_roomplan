import 'package:flutter/material.dart';
import 'package:flutter_object_capture_example/controllers/reconstruct_controller.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_object_capture_example/views/reconstruct_page.dart';
import 'package:flutter_object_capture_example/widgets/progress_card/progress_card.dart';
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

  tearDown(() => native.uninstall());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
  }

  Future<void> pumpPage(WidgetTester tester) async {
    // Tall surface: the list is lazy and the page has one more button now.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ReconstructPage(controller: controller)),
    );
  }

  Finder button(String label) => find.ancestor(
        of: find.text(label),
        matching: find.bySubtype<ButtonStyleButton>(),
      );

  testWidgets('Start with no folder shows a message, native untouched', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text(AppStrings.noFolderChosen), findsOneWidget);
    await tester.tap(button(AppStrings.start));
    await settle(tester);
    expect(find.text(AppStrings.errorNoFolder), findsOneWidget);
    expect(native.startCalls, 0);
  });

  testWidgets('empty file name shows a message', (tester) async {
    controller.setImagesDirectory('/photos');
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(button(AppStrings.start));
    await settle(tester);
    expect(find.text(AppStrings.errorNoName), findsOneWidget);
    expect(native.startCalls, 0);
  });

  testWidgets('Cancel is disabled and harmless when idle', (tester) async {
    await pumpPage(tester);
    final cancel = tester.widget<ButtonStyleButton>(
      button(AppStrings.cancel),
    );
    expect(cancel.onPressed, isNull);
    await tester.tap(button(AppStrings.cancel), warnIfMissed: false);
    await settle(tester);
    expect(native.startCalls, 0);
  });

  testWidgets('double tap on Start starts once and locks the form', (
    tester,
  ) async {
    controller.setImagesDirectory('/photos');
    await pumpPage(tester);
    await tester.tap(button(AppStrings.start));
    await settle(tester);
    await tester.tap(button(AppStrings.start), warnIfMissed: false);
    await settle(tester);
    expect(native.startCalls, 1);
    expect(
      tester.widget<ButtonStyleButton>(button(AppStrings.start)).onPressed,
      isNull,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('shows progress, issues and notices while running', (
    tester,
  ) async {
    controller.setImagesDirectory('/photos');
    await pumpPage(tester);
    await tester.tap(button(AppStrings.start));
    await settle(tester);
    native.progress(0.5, seconds: 65);
    native.sampleIssue(7, reason: 'blurry');
    native.sampleIssue(8, skipped: true);
    native.notice('stitchingIncomplete');
    await settle(tester);
    expect(find.byType(ProgressCard), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.textContaining('1 min 5 s left'), findsOneWidget);
    expect(find.text('Photo rejected #7: blurry'), findsOneWidget);
    expect(find.text('Photo skipped #8'), findsOneWidget);
    expect(find.text(AppStrings.noticeStitching), findsOneWidget);
  });

  testWidgets('Cancel while running ends with a cancelled message', (
    tester,
  ) async {
    controller.setImagesDirectory('/photos');
    await pumpPage(tester);
    await tester.tap(button(AppStrings.start));
    await settle(tester);
    await tester.tap(button(AppStrings.cancel));
    await settle(tester);
    native.nativeError('cancelled');
    await settle(tester);
    expect(native.cancelCalls, 1);
    expect(find.text(AppStrings.errorCancelled), findsOneWidget);
    expect(
      tester.widget<ButtonStyleButton>(button(AppStrings.start)).onPressed,
      isNotNull,
    );
  });

  testWidgets('storage error shows its own message', (tester) async {
    controller.setImagesDirectory('/photos');
    await pumpPage(tester);
    await tester.tap(button(AppStrings.start));
    await settle(tester);
    native.nativeError(
      'insufficient_storage',
      details: {'requiredBytes': 1048576},
    );
    await settle(tester);
    expect(find.textContaining(AppStrings.errorStorage), findsOneWidget);
    expect(find.textContaining('1.0 MB'), findsOneWidget);
  });

  testWidgets('completed opens the result page', (tester) async {
    controller.setImagesDirectory('/photos');
    await pumpPage(tester);
    await tester.tap(button(AppStrings.start));
    await settle(tester);
    native.completed('/docs/model.usdz', 3145728);
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.resultTitle), findsOneWidget);
    expect(find.text('/docs/model.usdz'), findsOneWidget);
    expect(find.text('3.0 MB'), findsOneWidget);
  });
}
