import 'package:example/main.dart';
import 'package:example/views/scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens scanner and advanced pages without exceptions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ScannerPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.byType(ScannerPage))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(find.text('Advanced Room Scanning'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
