import 'package:flutter/material.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_object_capture_example/controllers/reconstruct_controller.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_object_capture_example/views/reconstruct_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;

  setUp(() => native = FakeNative()..install());
  tearDown(() => native.uninstall());

  Future<ReconstructController> pumpPage(
    WidgetTester tester,
    List<ObjectDetail> details,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ReconstructController(
      documentsPath: () async => '/docs',
      supportedDetails: details,
    );
    await tester.pumpWidget(
      MaterialApp(home: ReconstructPage(controller: controller)),
    );
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    return controller;
  }

  testWidgets('hidden when only one detail is supported', (tester) async {
    await pumpPage(tester, const [ObjectDetail.reduced]);
    expect(find.text(AppStrings.detailLabel), findsNothing);
  });

  testWidgets('shown with several details and picking one updates form', (
    tester,
  ) async {
    final controller = await pumpPage(tester, ObjectDetail.values);
    expect(find.text(AppStrings.detailLabel), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<ObjectDetail>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.detailFull).last);
    await tester.pumpAndSettle();
    expect(controller.form.detail, ObjectDetail.full);
  });

  testWidgets('disabled while a reconstruction runs', (tester) async {
    final controller = await pumpPage(tester, ObjectDetail.values);
    controller.setImagesDirectory('/photos');
    await tester.tap(find.text(AppStrings.start));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    final field = tester.widget<DropdownButtonFormField<ObjectDetail>>(
      find.byType(DropdownButtonFormField<ObjectDetail>),
    );
    expect(field.onChanged, isNull);
    native.nativeError('cancelled');
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
  });
}
