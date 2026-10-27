import 'package:dynamotivation_software_hub_ubuntu/app.dart';
import 'package:dynamotivation_software_hub_ubuntu/presentation/controllers/hub_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

import 'yaru_window_mock.dart';

Future<HubController> _pump(
  WidgetTester tester, {
  double textScale = 1,
  bool highContrast = false,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(highContrast: highContrast);
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
  final controller = HubController(
    HubUseCases(
      InMemoryPackageRepository(refreshDelay: Duration.zero),
      InMemorySettingsRepository(),
    ),
  );
  await controller.load();
  mockYaruWindowChannel();
  await tester.pumpWidget(DynamotivationUbuntuApp(controller: controller));
  await tester.pump(const Duration(seconds: 1));
  return controller;
}

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('Ctrl+, opens settings and Esc closes them', (tester) async {
    await _pump(tester);
    expect(find.text('Automatically check for updates'), findsNothing);
    await _ctrl(tester, LogicalKeyboardKey.comma);
    expect(find.text('Automatically check for updates'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Automatically check for updates'), findsNothing);
  });

  testWidgets('Ctrl+F focuses the search box', (tester) async {
    await _pump(tester);
    await _ctrl(tester, LogicalKeyboardKey.keyF);
    await tester.enterText(find.byType(EditableText).first, 'geo');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltips name the shortcut for active keyboard layout', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byTooltip(RegExp(r'\((Strg|Ctrl)\+,\)$')), findsOneWidget);
  });

  testWidgets('no overflow at 200% text scale', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in high contrast', (tester) async {
    await _pump(tester, highContrast: true);
    expect(tester.takeException(), isNull);
  });
}
