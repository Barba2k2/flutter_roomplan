import 'package:flutter/material.dart';
import 'package:flutter_object_capture_example/controllers/result_controller.dart';
import 'package:flutter_object_capture_example/models/result_info.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_object_capture_example/views/result_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const info = ResultInfo(path: '/nope/model.usdz', fileSizeBytes: 5242880);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ResultPage(controller: ResultController(info))),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  testWidgets('shows path and size', (tester) async {
    await pumpPage(tester);
    expect(find.text('/nope/model.usdz'), findsOneWidget);
    expect(find.text('5.0 MB'), findsOneWidget);
  });

  testWidgets('missing file disables share and says why', (tester) async {
    await pumpPage(tester);
    expect(find.text(AppStrings.resultMissing), findsOneWidget);
    final share = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(AppStrings.resultShare),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(share.onPressed, isNull);
  });

  testWidgets('back button leaves the page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ResultPage(controller: ResultController(info)),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.resultBack));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.resultTitle), findsNothing);
  });
}
