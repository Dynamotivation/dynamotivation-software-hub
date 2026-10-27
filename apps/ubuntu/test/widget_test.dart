import 'dart:ui' show Size;

import 'package:dynamotivation_software_hub_ubuntu/app.dart';
import 'package:dynamotivation_software_hub_ubuntu/presentation/controllers/hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

void main() {
  testWidgets('Ubuntu frontend smoke test: shows the selected package', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = HubController(
      HubUseCases(
        InMemoryPackageRepository(refreshDelay: Duration.zero),
        InMemorySettingsRepository(),
      ),
    );
    await controller.load();

    await tester.pumpWidget(DynamotivationUbuntuApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text(controller.selected!.name), findsWidgets);
  });
}
