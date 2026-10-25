import 'package:flutter_object_capture_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the package name', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('flutter_object_capture'), findsOneWidget);
  });
}
