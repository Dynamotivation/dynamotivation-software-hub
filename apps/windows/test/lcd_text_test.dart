import 'package:dynamotivation_software_hub/presentation/widgets/lcd_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(ByteData, int)> _render(
  WidgetTester tester, {
  required Color fg,
  required Color bg,
}) async {
  tester.view.physicalSize = const Size(80, 60);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: 80,
          height: 60,
          color: bg,
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 10, top: 10),
          // Ahem draws every glyph as a solid 1 em square.
          child: LcdText(
            'M',
            style: const TextStyle(fontFamily: 'Ahem', fontSize: 20),
            color: fg,
            background: bg,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  late ByteData data;
  late int width;
  await tester.runAsync(() async {
    final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage();
    width = img.width;
    data = (await img.toByteData())!;
  });
  return (data, width);
}

List<int> _px((ByteData, int) img, int x, int y) {
  final i = (y * img.$2 + x) * 4;
  return [for (var k = 0; k < 3; k++) img.$1.getUint8(i + k)];
}

void main() {
  for (final (name, fg, bg) in [
    ('light on dark', const Color(0xFFE6E6E6), const Color(0xFF202124)),
    ('dark on light', const Color(0xFF202124), const Color(0xFFF3F3F3)),
  ]) {
    testWidgets(
      'LcdText $name: solid inside, background outside, fringed edge',
      (tester) async {
        final img = await _render(tester, fg: fg, bg: bg);
        int c(double v) => (v * 255).round();
        final fgRgb = [c(fg.r), c(fg.g), c(fg.b)];
        final bgRgb = [c(bg.r), c(bg.g), c(bg.b)];
        List<int> close(List<int> a, List<int> e) => [
          for (var i = 0; i < 3; i++) (a[i] - e[i]).abs(),
        ];
        // Interior (full coverage in all three passes) is exactly the text colour.
        expect(
          close(_px(img, 20, 20), fgRgb).every((d) => d <= 2),
          isTrue,
          reason: 'interior ${_px(img, 20, 20)} vs $fgRgb',
        );
        // Far outside is the untouched background.
        expect(close(_px(img, 2, 2), bgRgb).every((d) => d <= 1), isTrue);
        // Left edge: the blue pass reaches one pixel further left, so the pixel
        // just outside the glyph is tinted in blue only.
        final left = _px(img, 9, 20);
        expect(left[0], bgRgb[0]);
        expect(left[1], bgRgb[1]);
        expect(left[2], isNot(bgRgb[2]), reason: 'blue fringe missing: $left');
        // Pixel inside the glyph's left edge: red covered a third less than
        // blue/green, so channels differ.
        final inner = _px(img, 10, 20);
        expect(
          inner[0],
          isNot(inner[2]),
          reason: 'no per-channel edge: $inner',
        );
      },
    );
  }

  testWidgets('only one copy is selectable and exposed to semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final registrar = _CountingRegistrar();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: DefaultSelectionStyle(
            selectionColor: const Color(0x66338FFF),
            child: SelectionRegistrarScope(
              registrar: registrar,
              child: const LcdText(
                'Hello',
                color: Color(0xFFFFFFFF),
                background: Color(0xFF000000),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Hello'), findsNWidgets(3));
    expect(find.bySemanticsLabel('Hello'), findsOneWidget);
    expect(registrar.count, 1, reason: 'only the green pass may be selectable');
    handle.dispose();
  });
}

class _CountingRegistrar extends SelectionRegistrar {
  int count = 0;

  @override
  void add(Selectable selectable) => count++;

  @override
  void remove(Selectable selectable) => count--;
}
