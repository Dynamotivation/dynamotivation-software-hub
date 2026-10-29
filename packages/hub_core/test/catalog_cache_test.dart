import 'dart:io';

import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

final _uri = Uri.parse('https://example.test/v1/catalog.json/');

void main() {
  group('cacheDirectory', () {
    test('windows uses LOCALAPPDATA', () {
      final d = cacheDirectory(
        'Hub',
        operatingSystem: 'windows',
        environment: {'LOCALAPPDATA': r'C:\Users\u\AppData\Local'},
      );
      expect(d.path, r'C:\Users\u\AppData\Local\Hub\Cache');
    });

    test('macos uses Library/Caches', () {
      final d = cacheDirectory(
        'Hub',
        operatingSystem: 'macos',
        environment: {'HOME': '/Users/u'},
      );
      expect(d.path, '/Users/u/Library/Caches/Hub');
    });

    test('linux prefers XDG_CACHE_HOME, else ~/.cache', () {
      expect(
        cacheDirectory(
          'Hub',
          operatingSystem: 'linux',
          environment: {'XDG_CACHE_HOME': '/x', 'HOME': '/h'},
        ).path,
        '/x/Hub',
      );
      expect(
        cacheDirectory(
          'Hub',
          operatingSystem: 'linux',
          environment: {'HOME': '/h'},
        ).path,
        '/h/.cache/Hub',
      );
    });
  });

  group('CatalogCache', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('catalog_cache_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('serves the last good response when the fetch fails', () async {
      var online = true;
      final cache = CatalogCache(
        dir,
        fetch: (u) async {
          if (!online) throw CatalogUnavailable(u, 'offline');
          return '{"software":[]}';
        },
      );
      expect(await cache.fetch(_uri), '{"software":[]}');
      expect(cache.servedStale, isFalse);

      online = false;
      expect(await cache.fetch(_uri), '{"software":[]}');
      expect(cache.servedStale, isTrue);
      expect(cache.lastFetchError, isNotNull);
    });

    test('rethrows when nothing is cached', () async {
      final cache = CatalogCache(
        dir,
        fetch: (u) async => throw CatalogUnavailable(u, 'offline'),
      );
      expect(() => cache.fetch(_uri), throwsA(isA<CatalogUnavailable>()));
    });

    test('an unwritable cache does not break a load', () async {
      final blocker = File('${dir.path}/file')..writeAsStringSync('x');
      final cache = CatalogCache(
        Directory('${blocker.path}/sub'),
        fetch: (_) async => 'ok',
      );
      expect(await cache.fetch(_uri), 'ok');
    });
  });
}
