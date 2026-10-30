import 'package:dynamotivation_software_hub/app.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

import 'window_manager_mock.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = HubController(
      HubUseCases(
        InMemoryPackageRepository(testCatalog(), refreshDelay: Duration.zero),
        InMemorySettingsRepository(),
      ),
    );
    await controller.load();
    mockWindowManagerChannel();

    await tester.pumpWidget(DynamotivationApp(controller: controller));
    await tester.pump();
    expect(find.text('Software Hub'), findsOneWidget);
  });
}
