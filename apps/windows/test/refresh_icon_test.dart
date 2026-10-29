import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dynamotivation_software_hub/presentation/theme/dynamotivation_theme.dart';
import 'package:dynamotivation_software_hub/presentation/widgets/package_sidebar.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('refresh icon never crops and spins on its ring centre', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(120, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final frames = <ui.Image>[];
    for (final deg in [0, 45, 90, 135, 180, 225, 270, 315]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        FluentApp(
          debugShowCheckedModeBanner: false,
          theme: DynamotivationTheme.darkTheme(),
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: Container(
                width: 100,
                height: 100,
                color: const Color(0xFF000000),
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: deg * math.pi / 180,
                  child: const SpinnableRefreshIcon(size: 70),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final centre = tester.getCenter(find.byType(SpinnableRefreshIcon));
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await b.toImage();
        frames.add(img);
        final raw = (await img.toByteData())!;
        var x0 = 999, y0 = 999, x1 = -1, y1 = -1;
        for (var y = 0; y < img.height; y++) {
          for (var x = 0; x < img.width; x++) {
            if (raw.getUint8((y * img.width + x) * 4 + 1) > 20) {
              x0 = math.min(x0, x);
              x1 = math.max(x1, x);
              y0 = math.min(y0, y);
              y1 = math.max(y1, y);
            }
          }
        }
        // The 98 px paint canvas sits inside the 100 px frame: ink touching
        // the frame edge would mean the arrowhead is being cropped.
        expect(x0, greaterThanOrEqualTo(1), reason: 'cropped at $deg deg');
        expect(y0, greaterThanOrEqualTo(1), reason: 'cropped at $deg deg');
        expect(x1, lessThanOrEqualTo(98), reason: 'cropped at $deg deg');
        expect(y1, lessThanOrEqualTo(98), reason: 'cropped at $deg deg');
        expect(centre, const Offset(60, 60));
      });
    }
    await tester.runAsync(() async {
      final w = frames.first.width, h = frames.first.height;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      for (var i = 0; i < frames.length; i++) {
        c.drawImage(frames[i], Offset(i * w.toDouble(), 0), Paint());
      }
      final img = await rec.endRecording().toImage(w * frames.length, h);
      File('D:/worktrees/DynamotivationSoftwareHub/spin_montage.png')
          .writeAsBytesSync(
            (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer
                .asUint8List(),
          );
    });
  });
}
