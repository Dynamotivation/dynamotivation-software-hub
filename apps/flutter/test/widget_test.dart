import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamotivation_software_hub/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DynamotivationApp());
    expect(find.text('Software Hub'), findsOneWidget);
  });
}
