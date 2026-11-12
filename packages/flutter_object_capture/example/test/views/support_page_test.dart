import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_object_capture_example/controllers/support_controller.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_object_capture_example/views/support_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;

  setUp(() => native = FakeNative()..install());
  tearDown(() => native.uninstall());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SupportPage(controller: SupportController())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('supported device shows limits and Continue', (tester) async {
    await pumpPage(tester);
    expect(find.text(AppStrings.limitsTitle), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('4096'), findsOneWidget);
    expect(find.text(AppStrings.deviceNote), findsOneWidget);
    expect(find.text(AppStrings.continueToReconstruct), findsOneWidget);
    expect(find.text(AppStrings.unsupportedHeadline), findsNothing);
  });

  testWidgets('unsupported device hides Continue and offers retry', (
    tester,
  ) async {
    native.supported = false;
    await pumpPage(tester);
    expect(find.text(AppStrings.unsupportedHeadline), findsOneWidget);
    expect(find.text(AppStrings.continueToReconstruct), findsNothing);
    expect(find.text(AppStrings.checkAgain), findsOneWidget);
  });

  testWidgets('getLimits error shows a message', (tester) async {
    native.limitsError = PlatformException(code: 'reconstruction_failed');
    await pumpPage(tester);
    expect(find.textContaining(AppStrings.errorFailed), findsOneWidget);
    expect(find.text(AppStrings.continueToReconstruct), findsNothing);
  });

  testWidgets('Check again asks the device again', (tester) async {
    native.supported = false;
    await pumpPage(tester);
    native.supported = true;
    await tester.tap(find.text(AppStrings.checkAgain));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.continueToReconstruct), findsOneWidget);
  });

  testWidgets('Continue opens the reconstruct page', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text(AppStrings.continueToReconstruct));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reconstructTitle), findsOneWidget);
  });
}
