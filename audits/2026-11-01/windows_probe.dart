// Diagnostic collector: captured exceptions are findings, not passing accessibility assertions.
import 'dart:ui' show Tristate;

import 'package:dynamotivation_software_hub/app.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

import '../../apps/windows/test/window_manager_mock.dart';

void main() {
  for (final (width, height) in [(1280.0, 900.0), (560.0, 580.0)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('diagnostic ${width}x$height scale=$scale', (tester) async {
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(() {
          tester.view.reset();
          tester.platformDispatcher.clearAllTestValues();
        });
        final semantics = tester.ensureSemantics();
        final c = HubController(
          HubUseCases(
            InMemoryPackageRepository(
              testCatalog(),
              refreshDelay: Duration.zero,
            ),
            InMemorySettingsRepository(),
          ),
        );
        await c.load();
        mockWindowManagerChannel();
        await tester.pumpWidget(DynamotivationApp(controller: c));
        await tester.pumpAndSettle();
        print(
          'MAIN ${width}x$height scale=$scale exception=${tester.takeException()}',
        );
        if (scale == 1) {
          for (var i = 0; i < 22; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            final focus = FocusManager.instance.primaryFocus;
            final ancestors = <String>[];
            focus?.context?.visitAncestorElements((e) {
              if (e.widget is Semantics)
                ancestors.add(
                  'label:${(e.widget as Semantics).properties.label}',
                );
              ancestors.add(e.widget.runtimeType.toString());
              return ancestors.length < 7;
            });
            print('TAB $i ${focus?.debugLabel} $ancestors');
          }
        }
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.comma);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        print(
          'SETTINGS ${width}x$height scale=$scale exception=${tester.takeException()}',
        );
        if (scale == 1) {
          for (var i = 0; i < 10; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            final focus = FocusManager.instance.primaryFocus;
            final ancestors = <String>[];
            focus?.context?.visitAncestorElements((e) {
              ancestors.add(e.widget.runtimeType.toString());
              return ancestors.length < 10;
            });
            print('SETTAB $i $ancestors');
          }
        }
        void visit(SemanticsNode n) {
          final d = n.getSemanticsData();
          if ((d.flagsCollection.isToggled != Tristate.none ||
                  d.flagsCollection.isChecked.toString() !=
                      "CheckedState.none") ||
              (d.flagsCollection.isButton && d.label.isEmpty))
            print(
              'NODE label="${d.label}" flags=${d.flagsCollection} actions=${d.actions}',
            );
          n.visitChildren((v) {
            visit(v);
            return true;
          });
        }

        visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
        for (final e in find.byType(AnimatedSwitcher).evaluate()) {
          print(
            'REDUCED switch duration=${(e.widget as AnimatedSwitcher).duration}',
          );
        }
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }
  }
}
