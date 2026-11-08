import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dynamotivation_software_hub/presentation/widgets/click_cursor.dart';

Future<void> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump();
}

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(FluentApp(home: Center(child: child)));

  Future<String> cursorAt(WidgetTester tester, Finder target) async {
    String kind = 'basic';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.mouseCursor,
      (call) async {
        if (call.method == 'activateSystemCursor') {
          kind = (call.arguments as Map)['kind'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.mouseCursor,
        null,
      ),
    );
    await _hover(tester, target);
    return kind;
  }

  testWidgets('an enabled button shows the hand cursor', (tester) async {
    await pump(tester, ClickButton(onPressed: () {}, child: const Text('Go')));
    expect(await cursorAt(tester, find.text('Go')), 'click');
  });

  testWidgets('a disabled button keeps the arrow', (tester) async {
    await pump(tester, const ClickButton(onPressed: null, child: Text('Go')));
    expect(await cursorAt(tester, find.text('Go')), 'basic');
  });

  testWidgets('a filled button shows the hand cursor', (tester) async {
    await pump(
      tester,
      ClickFilledButton(onPressed: () {}, child: const Text('Go')),
    );
    expect(await cursorAt(tester, find.text('Go')), 'click');
  });
}
