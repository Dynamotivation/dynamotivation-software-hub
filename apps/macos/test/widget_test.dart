import 'dart:ui' show Size;

import 'package:dynamotivation_software_hub_macos/app.dart';
import 'package:dynamotivation_software_hub_macos/presentation/controllers/hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

void main() {
  testWidgets('shows the selected package', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = HubController(
      HubUseCases(
        InMemoryPackageRepository(testCatalog(), refreshDelay: Duration.zero),
        InMemorySettingsRepository(),
      ),
    );
    await controller.load();

    await tester.pumpWidget(DynamotivationMacosApp(controller: controller));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text(controller.selected!.name), findsWidgets);
  });
}
