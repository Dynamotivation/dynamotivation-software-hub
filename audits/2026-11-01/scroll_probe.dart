// Diagnostic collector: observations are not passing accessibility assertions.
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_scroll/hub_scroll.dart';

void main() {
  testWidgets('scroll accessibility diagnostic', (tester) async {
    final c = ScrollController();
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SmoothScroll(
            controller: c,
            child: ListView(
              controller: c,
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
    var scrollActions = 0;
    var scrollUpAvailable = 0;
    var scrollDownAvailable = 0;
    void visit(SemanticsNode n) {
      final d = n.getSemanticsData();
      // Flutter maps directions by AxisDirection: at the top of a downward
      // list, scrollUp means "scroll toward the end". Count capability in
      // either direction; a screen reader gets implicit scrolling + extents.
      if (d.hasAction(SemanticsAction.scrollDown) ||
          d.hasAction(SemanticsAction.scrollUp) ||
          (d.hasFlag(SemanticsFlag.hasImplicitScrolling) &&
              d.hasAction(SemanticsAction.scrollToOffset))) {
        scrollActions++;
      }
      if (d.hasAction(SemanticsAction.scrollUp)) scrollUpAvailable++;
      if (d.hasAction(SemanticsAction.scrollDown)) scrollDownAvailable++;
      n.visitChildren((v) {
        visit(v);
        return true;
      });
    }

    visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    print('SCROLLABLE NODES WITH SCROLL SEMANTICS=$scrollActions');
    print(
      'SCROLLUP(action)=#$scrollUpAvailable SCROLLDOWN(action)=#$scrollDownAvailable',
    );
    final p = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(p.hover(const Offset(100, 100)));
    await tester.sendEventToBinding(p.scroll(const Offset(0, 100)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    print('REDUCED WHEEL offset after50ms=${c.offset} target=100');
    await tester.pumpAndSettle();
    h.dispose();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
