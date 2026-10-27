import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_scroll/hub_scroll.dart';

void main() {
  testWidgets('wheel scrolls eased, not as a single jump', (tester) async {
    final controller = ScrollController();
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
}
