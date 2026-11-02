import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_scroll/hub_scroll.dart';

void main() {
  testWidgets('wheel scrolls eased, not as a single jump', (tester) async {
    final controller = SmoothScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SmoothScroll(
          controller: controller,
          child: ListView(
            controller: controller,
            physics: smoothScrollPhysics,
            children: [
              for (var i = 0; i < 50; i++)
                SizedBox(height: 50, child: Text('$i')),
            ],
          ),
        ),
      ),
    );
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 100)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 100)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(100));
    await tester.pumpAndSettle();
    expect(controller.offset, 100);
  });
  Future<void> pumpScroll(
    WidgetTester tester,
    SmoothScrollController controller, {
    bool reduced = false,
  }) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: SmoothScroll(
          controller: controller,
          child: ListView(
            controller: controller,
            physics: smoothScrollPhysics,
            children: [
              for (var i = 0; i < 50; i++)
                SizedBox(height: 50, child: Text('$i')),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> wheel(WidgetTester tester, double distance) async {
    final pointer = TestPointer(2, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 100)));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, distance)));
    await tester.pump();
  }

  testWidgets(
    'reduced motion scrolls immediately and stops an in-flight tween',
    (tester) async {
      final controller = SmoothScrollController();
      await pumpScroll(tester, controller);
      await wheel(tester, 100);
      await tester.pump(const Duration(milliseconds: 30));
      expect(controller.offset, inExclusiveRange(0, 100));
      await pumpScroll(tester, controller, reduced: true);
      expect(controller.offset, 100);
      await wheel(tester, 100);
      expect(controller.offset, 200);
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.offset, 200);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets('screen-reader scroll and touch drag retain standard behavior', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = SmoothScrollController();
    await pumpScroll(tester, controller);
    tester.semantics.scrollUp();
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    final before = controller.offset;
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(before));
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('Page Down and Page Up work from focused scroll content', (
    tester,
  ) async {
    final controller = SmoothScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmoothScroll(
            controller: controller,
            child: ListView(
              controller: controller,
              physics: smoothScrollPhysics,
              children: [
                const Focus(autofocus: true, child: Text('Start')),
                for (var i = 0; i < 50; i++)
                  SizedBox(height: 50, child: Text('$i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    final before = controller.offset;
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(controller.offset, lessThan(before));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
