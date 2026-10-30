import 'dart:io';
import 'dart:typed_data';

import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('icon_cache_'));
  tearDown(() => dir.deleteSync(recursive: true));

  final bytes = Uint8List.fromList([1, 2, 3]);

  test('fetches once, then reads from disk', () async {
    var fetches = 0;
    final cache = IconCache(
      dir,
      fetch: (_) async {
        fetches++;
        return bytes;
      },
    );
    expect(await cache.bytes('https://x.test/a.webp'), bytes);
    expect(await cache.bytes('https://x.test/a.webp'), bytes);
    expect(fetches, 1);

    // A new process finds the stored file too.
    final again = IconCache(dir, fetch: (_) async => throw 'offline');
    expect(await again.bytes('https://x.test/a.webp'), bytes);
  });

  test('concurrent requests share one download', () async {
    var fetches = 0;
    final cache = IconCache(
      dir,
      fetch: (_) async {
        fetches++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return bytes;
      },
    );
    await Future.wait([
      cache.bytes('u'),
      cache.bytes('u'),
      cache.prefetch('u'),
    ]);
    expect(fetches, 1);
  });

  test('prefetch reports failure instead of throwing', () async {
    final cache = IconCache(
      dir,
      fetch: (_) async => throw const HttpException('x'),
    );
    expect(await cache.prefetch('u'), isFalse);
  });

  test('discard makes the next read fetch again', () async {
    var fetches = 0;
    final cache = IconCache(
      dir,
      fetch: (_) async {
        fetches++;
        return bytes;
      },
    );
    await cache.bytes('u');
    await cache.discard('u');
    await cache.bytes('u');
    expect(fetches, 2);
  });
}
