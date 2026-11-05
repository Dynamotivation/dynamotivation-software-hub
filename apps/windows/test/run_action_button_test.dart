import 'dart:ui' show SemanticsAction;

import 'package:dynamotivation_software_hub/presentation/widgets/run_action_button.dart';
import 'package:dynamotivation_software_hub/presentation/theme/dynamotivation_theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_l10n/hub_l10n.dart';

void main() {
  for (final locale in ['en', 'de']) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('run actions reflow at $scale in $locale with fixed width', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(560, 580);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        double? width;
        for (final running in [false, true]) {
          await tester.pumpWidget(
            FluentApp(
              theme: DynamotivationTheme.lightTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(locale),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Center(
                child: RunActionButton(
                  name: 'Test app',
                  running: running,
                  busy: false,
                  enabled: true,
                  primary: false,
                  onLaunch: (_) {},
                  onForceClose: () {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final size = tester.getSize(
            find.byKey(const ValueKey('run-action-footprint')),
          );
          width ??= size.width;
          expect(size.width, width);
          for (final element in find.byType(Button).evaluate()) {
            final target = tester.getSize(find.byWidget(element.widget));
            expect(target.width, greaterThanOrEqualTo(24));
            expect(target.height, greaterThanOrEqualTo(24));
          }
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
    'fixed width, Ctrl click, keyboard activation and Yes/No confirmation',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var running = false;
      final launches = <bool>[];
      var stops = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      Widget app() => FluentApp(
        theme: DynamotivationTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Center(
          child: RunActionButton(
            name: 'Test app',
            running: running,
            busy: false,
            enabled: true,
            primary: false,
            focusNode: focus,
            onLaunch: launches.add,
            onForceClose: () {
              stops++;
            },
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final footprint = find.byKey(const ValueKey('run-action-footprint'));
      final width = tester.getSize(footprint).width;
      expect(width, 240);
      await tester.tap(find.text('Launch'));
      expect(launches, [false]);
      running = true;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(tester.getSize(footprint).width, width);
      final state = tester
          .getSemantics(find.bySemanticsLabel('Launch another instance'))
          .getSemanticsData();
      expect(state.value, 'Running');
      expect(state.hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.text('Running'));
      expect(launches, [false]);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await tester.tap(find.text('Running'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(launches, [false, true]);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(launches, [false, true, true]);
      final close = find.byIcon(FluentIcons.chrome_close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(ContentDialog), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await tester.tap(close);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('Force close Test app?'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(stops, 0);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Force close application',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(ContentDialog), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(stops, 1);
      expect(tester.getSize(footprint).width, width);
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    },
  );
}
