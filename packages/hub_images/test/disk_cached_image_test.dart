import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_images/hub_images.dart';

// 1x1 PNG; any format Flutter can decode works for the adapter mechanics.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
);

Future<void> _load(DiskCachedImage image) {
  final done = Completer<void>();
  image
      .resolve(ImageConfiguration.empty)
      .addListener(
        ImageStreamListener(
          (_, _) => done.isCompleted ? null : done.complete(),
          onError: (e, _) => done.isCompleted ? null : done.completeError(e),
        ),
      );
  return done.future;
}

void main() {
  test('decodes the icon the cache provides', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('icons_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final icons = IconCache(dir, fetch: (_) async => _png);
      await _load(DiskCachedImage('https://x.test/i.webp', icons));
      expect(dir.listSync().whereType<File>(), isNotEmpty);
    });
  });

  test('drops a stored icon that does not decode', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('icons_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final icons = IconCache(dir, fetch: (_) async => utf8.encode('nope'));
      await expectLater(
        _load(DiskCachedImage('https://x.test/bad.webp', icons)),
        throwsA(anything),
      );
      expect(dir.listSync().whereType<File>(), isEmpty);
    });
  });

  test('images with the same url are equal', () {
    final icons = IconCache(Directory('x'));
    expect(DiskCachedImage('u', icons), DiskCachedImage('u', icons));
  });
}
