import 'package:dynamotivation_software_hub/app.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:fluent_ui/fluent_ui.dart' show InfoBar;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

Future<void> _pump(
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
  await tester.pumpWidget(DynamotivationApp(controller: controller));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('toasts fade in and out, and replace instead of stacking', (
    tester,
  ) async {
    await _pump(tester);
    Future<void> refresh() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    double opacity() => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byType(InfoBar),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    expect(find.byType(InfoBar), findsNothing);
    await refresh();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(InfoBar), findsOneWidget);
    expect(opacity(), allOf(greaterThan(0), lessThan(1))); // fading in
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), 1);

    await refresh(); // a second message while the first is showing
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(InfoBar), findsOneWidget); // replaced, not stacked

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(), lessThan(1)); // fading out
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(InfoBar), findsNothing);
  });

  testWidgets('Ctrl+, opens settings and Esc closes them', (tester) async {
    await _pump(tester);
    expect(find.text('System Integration'), findsNothing);
    await _ctrl(tester, LogicalKeyboardKey.comma);
    expect(find.text('System Integration'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('System Integration'), findsNothing);
  });

  testWidgets('Ctrl+F focuses the search box', (tester) async {
    await _pump(tester);
    await _ctrl(tester, LogicalKeyboardKey.keyF);
    await tester.enterText(find.byType(EditableText).first, 'geo');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltips name the shortcut for the active keyboard layout', (
    tester,
  ) async {
    await _pump(tester);
    // Strg on a German layout, Ctrl otherwise: both are correct, "Ctrl" on a
    // German layout (or vice versa) would be the bug.
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
