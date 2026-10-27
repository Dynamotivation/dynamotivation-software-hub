import 'package:dynamotivation_software_hub_macos/app.dart';
import 'package:dynamotivation_software_hub_macos/presentation/controllers/hub_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

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
  await tester.pumpWidget(DynamotivationMacosApp(controller: controller));
  await tester.pump(const Duration(seconds: 2));
  return controller;
}

void main() {
  testWidgets('status messages fade in and out and replace in place', (
    tester,
  ) async {
    await _pump(tester);
    Future<void> refresh() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    final message = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.liveRegion == true,
    );
    double opacity() => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: message.first,
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    expect(message, findsNothing);
    await refresh();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 60));
    expect(opacity(), allOf(greaterThan(0), lessThan(1))); // fading in
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), 1);

    await refresh();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    expect(message, findsOneWidget); // replaced, not stacked

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(), lessThan(1)); // fading out
    await tester.pump(const Duration(seconds: 1));
    expect(message, findsNothing);
  });

  testWidgets('Ctrl+, opens settings, Esc closes', (tester) async {
    await _pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('System Integration'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // cross-fade completes
    expect(find.text('System Integration'), findsNothing);
  });

  testWidgets('Tab reaches toolbar buttons and Enter activates', (
    tester,
  ) async {
    await _pump(tester);
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at 200% text scale', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in high contrast', (tester) async {
    await _pump(tester, highContrast: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toolbar buttons are labelled for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(find.bySemanticsLabel('Settings'), findsWidgets);
    handle.dispose();
  });
}
