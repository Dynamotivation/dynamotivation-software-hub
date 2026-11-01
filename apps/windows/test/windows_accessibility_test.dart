import 'dart:ui' show SemanticsAction, Tristate;

import 'package:dynamotivation_software_hub/app.dart';
import 'package:dynamotivation_software_hub/platform/windows_accessibility.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:dynamotivation_software_hub/presentation/pages/software_hub_page.dart';
import 'package:dynamotivation_software_hub/presentation/theme/dynamotivation_theme.dart';
import 'package:dynamotivation_software_hub/presentation/widgets/accessible_switch.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

import 'window_manager_mock.dart';

const _darkContrast = WindowsContrastPalette(
  enabled: true,
  window: Color(0xFF101010),
  text: Color(0xFFFFFF00),
  button: Color(0xFF101010),
  buttonText: Color(0xFFFFFF00),
  highlight: Color(0xFF00FFFF),
  highlightText: Color(0xFF101010),
  disabled: Color(0xFF909090),
);
const _lightContrast = WindowsContrastPalette(
  enabled: true,
  window: Color(0xFFFFFFEE),
  text: Color(0xFF000040),
  button: Color(0xFFFFFFEE),
  buttonText: Color(0xFF000040),
  highlight: Color(0xFF800040),
  highlightText: Color(0xFFFFFFEE),
  disabled: Color(0xFF606060),
);
const _off = WindowsContrastPalette(
  enabled: false,
  window: Color(0xFFFFFFFF),
  text: Color(0xFF000000),
  button: Color(0xFFFFFFFF),
  buttonText: Color(0xFF000000),
  highlight: Color(0xFF000000),
  highlightText: Color(0xFFFFFFFF),
  disabled: Color(0xFF808080),
);

Future<HubController> _pump(
  WidgetTester tester, {
  Size size = const Size(1020, 780),
  double scale = 1,
  WindowsAccessibility? accessibility,
  bool reduced = false,
  bool settings = false,
  InMemoryPackageRepository? repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduced);
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
  final controller = HubController(
    HubUseCases(
      repository ??
          InMemoryPackageRepository(testCatalog(), refreshDelay: Duration.zero),
      InMemorySettingsRepository(),
    ),
  );
  await controller.load();
  addTearDown(controller.dispose);
  mockWindowManagerChannel();
  await tester.pumpWidget(
    DynamotivationApp(
      controller: controller,
      accessibility: accessibility,
      initialSettingsOpen: settings,
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _settings(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.comma);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

bool _focusWithin(Finder finder) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  final targets = finder.evaluate().toSet();
  var found = targets.contains(context);
  context.visitAncestorElements((e) {
    if (targets.contains(e)) found = true;
    return !found;
  });
  return found;
}

void _semanticTap(WidgetTester tester, Finder finder) {
  // Resolve the effective merged node, rather than a hidden merged child.
  final node = tester.getSemantics(finder);
  expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  node.owner!.performAction(node.id, SemanticsAction.tap);
}

class _OfflineRepository extends InMemoryPackageRepository {
  _OfflineRepository() : super(testCatalog(), refreshDelay: Duration.zero);
  @override
  Future<void> refresh() async => throw CatalogUnavailable(
    Uri.parse('https://example.invalid/catalog'),
    'offline',
  );
}

void main() {
  testWidgets(
    'Windows palette updates live, overrides app theme, and restores brand',
    (tester) async {
      final source = WindowsAccessibility()..value = _darkContrast;
      addTearDown(source.dispose);
      final c = await _pump(tester, accessibility: source);
      await c.updateSettings(c.settings.copyWith(themeMode: AppThemeMode.dark));
      for (final palette in [_darkContrast, _lightContrast]) {
        source.value = palette;
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(SoftwareHubPage));
        final theme = FluentTheme.of(context);
        final tokens = DynTokens.of(context);
        expect(MediaQuery.highContrastOf(context), isTrue);
        expect(tokens.window, palette.window);
        expect(tokens.text, palette.text);
        expect(tokens.headerGradient.colors, [palette.window, palette.window]);
        expect(theme.resources.textFillColorPrimary, palette.text);
        expect(
          theme.resources.textOnAccentFillColorPrimary,
          palette.highlightText,
        );
        expect(theme.resources.controlFillColorDefault, palette.button);
        expect(theme.accentColor.normal, palette.highlight);
        expect(
          theme.brightness,
          palette.window.computeLuminance() < .5
              ? Brightness.dark
              : Brightness.light,
        );
        expect(
          tester.widget<Text>(find.text('Dynamotivation').first).style!.color,
          palette.text,
        );
      }
      source.value = _off;
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SoftwareHubPage));
      expect(MediaQuery.highContrastOf(context), isFalse);
      expect(DynTokens.of(context).window, DynTokens.dark.window);
      expect(
        DynTokens.of(context).headerGradient,
        DynTokens.dark.headerGradient,
      );
    },
  );

  testWidgets('native setting notification reloads the Windows palette', (
    tester,
  ) async {
    var enabled = false;
    var reads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      WindowsAccessibility.channel,
      (call) async {
        expect(call.method, 'readContrast');
        reads++;
        return {
          'enabled': enabled,
          'window': 0xff101010,
          'text': 0xffffff00,
          'button': 0xff101010,
          'buttonText': 0xffffff00,
          'highlight': 0xff00ffff,
          'highlightText': 0xff101010,
          'disabled': 0xff909090,
        };
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        WindowsAccessibility.channel,
        null,
      ),
    );
    final source = WindowsAccessibility();
    addTearDown(source.dispose);
    await source.initialize();
    expect(source.value!.enabled, isFalse);
    enabled = true;
    tester.binding.channelBuffers.push(
      WindowsAccessibility.channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('changed')),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(source.value!.enabled, isTrue);
    expect(source.value!.text, _darkContrast.text);
  });

  testWidgets('Tab reaches a package, focus is visible, and Enter selects it', (
    tester,
  ) async {
    final c = await _pump(tester);
    final target = c.packages.where((p) => p.isInstalled).first;
    final tile = find.byKey(ValueKey('package-${target.id}'));
    final before = tester.getTopLeft(find.text(target.name).first);
    for (var i = 0; i < 30 && !_focusWithin(tile); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(_focusWithin(tile), isTrue);
    expect(
      tester
          .widget<FocusBorder>(
            find.descendant(of: tile, matching: find.byType(FocusBorder)).first,
          )
          .focused,
      isTrue,
    );
    expect(tester.getTopLeft(find.text(target.name).first).dx, before.dx);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(c.selected!.id, target.id);
    final handle = tester.ensureSemantics();
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(tile).getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    handle.dispose();
  });

  testWidgets('settings entry and Escape return focus to search', (
    tester,
  ) async {
    await _pump(tester);
    expect(_focusWithin(find.byType(EditableText)), isTrue);
    await _settings(tester);
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'Settings back');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_focusWithin(find.byType(EditableText)), isTrue);
  });

  testWidgets('clear search and overflow menu expose semantic activation', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await tester.enterText(find.byType(EditableText), 'Geo');
    await tester.pumpAndSettle();
    final clear = find.byTooltip('Clear search');
    expect(
      tester
          .getSemantics(clear)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    _semanticTap(tester, clear);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    final more = find.byTooltip('More options');
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(more)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    _semanticTap(tester, more);
    await tester.pumpAndSettle();
    expect(find.text('Uninstall'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Uninstall'), findsNothing);
    handle.dispose();
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('minimum window remains usable at $scale text size', (
      tester,
    ) async {
      final c = await _pump(tester, size: const Size(560, 580), scale: scale);
      expect(tester.takeException(), isNull);
      final p = c.packages.where((p) => p.isInstalled).first;
      await tester.tap(find.byKey(ValueKey('package-${p.id}')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Launch').first);
      await tester.pumpAndSettle();
      expect(find.text('Launch').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settings(tester);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Show notifications'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reduced motion skips settings and toast animations', (
    tester,
  ) async {
    await _pump(tester, reduced: true);
    await _settings(tester);
    for (final transition in tester.widgetList<FadeTransition>(
      find.byType(FadeTransition),
    )) {
      expect(transition.opacity.value, 1);
    }
    for (final switcher in tester.widgetList<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    )) {
      expect(switcher.duration, Duration.zero);
    }
  });
  testWidgets('settings switches expose names, state and keyboard activation', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = await _pump(tester, settings: true);
    // The third of the four switches in the System Integration card.
    final toggle = find.byType(AccessibleSwitch).at(2);
    final rowTitle = find.text('Automatically check for updates');
    expect(rowTitle, findsOneWidget);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    final before = c.settings.autoCheckUpdates;
    final data = tester.getSemantics(toggle).getSemanticsData();
    expect(data.label, contains('Automatically check for updates'));
    expect(
      data.flagsCollection.isToggled,
      before ? Tristate.isTrue : Tristate.isFalse,
    );
    _semanticTap(tester, toggle);
    await tester.pumpAndSettle();
    expect(c.settings.autoCheckUpdates, !before);
    // Reach the control with Tab, then Space must toggle it back.
    for (var i = 0; i < 15 && !_focusWithin(toggle); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(_focusWithin(toggle), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(c.settings.autoCheckUpdates, before);
    handle.dispose();
  });

  testWidgets('errors persist until dismissed and expose a live region', (
    tester,
  ) async {
    await _pump(tester, repository: _OfflineRepository());
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    expect(find.byType(InfoBar), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
      findsWidgets,
    );
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(InfoBar), findsOneWidget);
    // Operate the real close control, not the callback directly.
    await tester.tap(
      find.descendant(
        of: find.byType(InfoBar),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InfoBar), findsNothing);
  });

  testWidgets('keyboard uninstall request leaves no menu behind after cancel', (
    tester,
  ) async {
    await _pump(tester);
    // Keyboard-only: focus More options, open, arrow to Uninstall, Enter.
    for (
      var i = 0;
      i < 60 && !_focusWithin(find.byTooltip('More options'));
      i++
    ) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(_focusWithin(find.byTooltip('More options')), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Uninstall'), findsOneWidget);
    final uninstallItem = find
        .ancestor(
          of: find.text('Uninstall'),
          matching: find.byType(HoverButton),
        )
        .first;
    for (var i = 0; i < 5 && !_focusWithin(uninstallItem); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(_focusWithin(uninstallItem), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(ContentDialog), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // activate Cancel
    await tester.pumpAndSettle();
    expect(find.byType(ContentDialog), findsNothing);
    // The menu that triggered the dialog must be gone: no menu entries.
    expect(find.text('Uninstall'), findsNothing);
    expect(find.text('Verify files'), findsNothing);
    // Focus stays in the application.
    expect(_focusWithin(find.byType(SoftwareHubPage)), isTrue);
  });

  testWidgets('success toasts announce, repeat and dismiss', (tester) async {
    await _pump(tester);
    // The F5 refresh path raises the user-initiated success feedback.
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    final liveRegions = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.liveRegion == true,
    );
    final toastNode = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          (w.key as ValueKey?)?.value is String &&
          ((w.key as ValueKey).value as String).startsWith('toast-'),
    );
    // The message lives in an announced live region and does not steal focus.
    expect(liveRegions, findsWidgets);
    expect(_focusWithin(find.byType(EditableText)), isTrue);
    final firstKey = tester.widget<Semantics>(toastNode.first).key!;
    // An identical message following the first is a fresh announcement: the
    // live-region node is rebuilt with a new key.
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    final secondKey = tester.widget<Semantics>(toastNode.first).key!;
    expect(secondKey, isNot(firstKey));
    // The close control actually dismisses it.
    await tester.tap(
      find.descendant(of: liveRegions.first, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InfoBar), findsNothing);
  });

  testWidgets(
    'Tab exits the package list and Shift+Tab returns across groups',
    (tester) async {
      await _pump(tester);
      for (
        var i = 0;
        i < 60 &&
            FocusManager.instance.primaryFocus?.debugLabel !=
                'Package primary action';
        i++
      ) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Package primary action',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('Package primary action'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('startup focus and search traversal follow defined rules', (
    tester,
  ) async {
    final c = await _pump(tester);
    // Entry: the search field owns focus so typing can start immediately.
    expect(_focusWithin(find.byType(EditableText)), isTrue);
    // Ctrl+F re-enters search after any trip away from it.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(_focusWithin(find.byType(EditableText)), isTrue);
    // Forward Tab leaves the search field into the sidebar rows.
    await tester.enterText(find.byType(EditableText), 'Geo');
    await tester.pumpAndSettle();
    final filtered = c.packages
        .where((p) => p.name.toLowerCase().contains('geo'))
        .first;
    final tile = find.byKey(ValueKey('package-${filtered.id}'));
    for (var i = 0; i < 20 && !_focusWithin(tile); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(
      _focusWithin(tile),
      isTrue,
      reason: 'forward traversal goes search -> package list',
    );
    // Enter selects the package.
    _semanticTap(tester, tile);
    await tester.pumpAndSettle();
    expect(c.selected, isNotNull);
    // Shift+Tab walks back into the header group (the settings button).
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 10 &&
          FocusManager.instance.primaryFocus?.debugLabel != 'Settings button';
      i++
    ) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Settings button');
  });

  testWidgets('Escape clears an active search but never the selection', (
    tester,
  ) async {
    final c = await _pump(tester);
    // The app starts with the first package selected; Escape must keep it.
    final initial = c.selected;
    expect(initial, isNotNull);
    await tester.enterText(find.byType(EditableText), 'Geo');
    await tester.pumpAndSettle();
    // The auto-selected first package keeps its title in the detail pane;
    // assert the sidebar filter instead: non-matching rows disappear.
    expect(
      find.byKey(const ValueKey('package-joins-the-battle-meme-generator')),
      findsNothing,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(c.selected!.id, initial!.id);
    // Switching selection, then searching, still survives Escape.
    final target = c.packages.where((p) => p.isInstalled).first;
    _semanticTap(tester, find.byKey(ValueKey('package-${target.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'x');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(c.selected!.id, target.id);
  });

  testWidgets('settings return focus goes to the entry point', (tester) async {
    await _pump(tester);
    // Reach the title-bar settings button via keyboard and open with it.
    for (
      var i = 0;
      i < 30 &&
          FocusManager.instance.primaryFocus?.debugLabel != 'Settings button';
      i++
    ) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Settings button');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Settings back');
    // Escape returns focus to the button that opened the page.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Settings button');
  });
}
