import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_images/hub_images.dart';

/// A 40x40 PNG: opaque everywhere when [full], else an opaque 10x20 block at
/// (5, 8) on a transparent background.
Future<Uint8List> _png({required bool full}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFFCC0000);
  canvas.drawRect(
    full
        ? const Rect.fromLTWH(0, 0, 40, 40)
        : const Rect.fromLTWH(5, 8, 10, 20),
    paint,
  );
  final image = await recorder.endRecording().toImage(40, 40);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<IconArtwork> analyse(String url, {required bool full}) async {
    final dir = Directory.systemTemp.createTempSync('icons_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final bytes = await _png(full: full);
    return IconArtwork.load(url, IconCache(dir, fetch: (_) async => bytes));
  }

  test('an icon with transparent edges is cropped to its shape', () async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      final artwork = await analyse('https://x.test/shape.webp', full: false);
      expect(artwork.isTrimmed, isTrue);
      expect(artwork.content, const Rect.fromLTWH(5, 8, 10, 20));
      expect(artwork.aspect, closeTo(0.5, 1e-9));
    });
  });

  test('a full square icon is shown whole', () async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      final artwork = await analyse('https://x.test/square.webp', full: true);
      expect(artwork.isTrimmed, isFalse);
      expect(artwork.aspect, 1);
    });
  });
}
