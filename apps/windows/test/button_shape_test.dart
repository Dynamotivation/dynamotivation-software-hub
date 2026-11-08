import 'dart:ui' show PointerDeviceKind;

import 'package:dynamotivation_software_hub/app.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

import 'window_manager_mock.dart';

void main() {
  for (final mode in [AppThemeMode.light, AppThemeMode.dark]) {
    testWidgets('secondary Launch matches primary corners in $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final package = testCatalog().first;
      final repository = InMemoryPackageRepository([
        package,
      ], refreshDelay: Duration.zero);
      final controller = HubController(
        HubUseCases(repository, InMemorySettingsRepository()),
      );
      await controller.load();
      await controller.updateSettings(
        controller.settings.copyWith(themeMode: mode),
      );
      mockWindowManagerChannel();
      await tester.pumpWidget(DynamotivationApp(controller: controller));
      await tester.pumpAndSettle();
      final launch = find.widgetWithText(Button, 'Launch');

      void expectMatchingCorners() {
        final containers = find.descendant(
          of: launch,
          matching: find.byType(AnimatedContainer),
        );
        final decoration =
            tester.widget<AnimatedContainer>(containers.first).decoration
                as ShapeDecoration;
        final radius = switch (decoration.shape) {
          RoundedRectangleBorder(:final borderRadius) => borderRadius,
          RoundedRectangleGradientBorder(:final borderRadius) => borderRadius,
          _ => null,
        };
        expect(radius, BorderRadius.circular(8));
      }

      expectMatchingCorners();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(launch));
      await tester.pumpAndSettle();
      expectMatchingCorners();
      await mouse.down(tester.getCenter(launch));
      await tester.pumpAndSettle();
      expectMatchingCorners();
      await mouse.up();
      await mouse.removePointer();
      await repository.save(package.copyWith(launchExecutable: ''));
      await tester.runAsync(controller.refresh);
      await tester.pumpAndSettle();
      expect(tester.widget<Button>(launch).onPressed, isNull);
      expectMatchingCorners();
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }

  testWidgets('filled buttons keep their rounded shape while refreshing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = HubController(
      HubUseCases(
        InMemoryPackageRepository(
          testCatalog(),
          refreshDelay: const Duration(milliseconds: 600),
        ),
        InMemorySettingsRepository(),
      ),
    );
    await c.load();
    for (final p in c.packages) {
      if (!p.isInstalled) {
        c.select(p);
        break;
      }
    }
    mockWindowManagerChannel();
    await tester.pumpWidget(DynamotivationApp(controller: c));
    await tester.pump(const Duration(seconds: 1));
    void expectRounded() {
      final f = find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(PhysicalModel),
      );
      expect(f, findsWidgets);
      for (final e in f.evaluate()) {
        expect(
          (e.widget as PhysicalModel).borderRadius,
          BorderRadius.circular(8),
        );
      }
    }

    expectRounded();
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expectRounded();
    }
  });
}
