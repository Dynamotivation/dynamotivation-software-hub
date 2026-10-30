import 'dart:convert';
import 'dart:io';

import '../application/errors.dart';
import 'website_package_repository.dart';

/// The per-user cache directory the OS and the user already know how to clear.
///
/// Not the temp directory: Windows Storage Sense, Disk Cleanup and many Linux
/// setups sweep temp on their own. These locations are cleared only deliberately.
///  - Windows: `%LOCALAPPDATA%\<app>\Cache`
///  - macOS: `~/Library/Caches/<app>`
///  - Linux: `$XDG_CACHE_HOME/<app>`, else `~/.cache/<app>`
///
/// [environment] and [operatingSystem] are injectable for tests.
Directory cacheDirectory(
  String app, {
  Map<String, String>? environment,
  String? operatingSystem,
}) {
  final env = environment ?? Platform.environment;
  final os = operatingSystem ?? Platform.operatingSystem;
  final home = env['HOME'] ?? env['USERPROFILE'];
  final String base;
  switch (os) {
    case 'windows':
      final local = env['LOCALAPPDATA'];
      if (local == null && home == null) {
        throw StateError('Neither LOCALAPPDATA nor USERPROFILE is set.');
      }
      base = local != null
          ? '$local\\$app\\Cache'
          : '$home\\AppData\\Local\\$app\\Cache';
    case 'macos':
      if (home == null) throw StateError('HOME is not set.');
      base = '$home/Library/Caches/$app';
    default:
      final xdg = env['XDG_CACHE_HOME'];
      if (xdg != null && xdg.isNotEmpty) {
        base = '$xdg/$app';
      } else if (home != null) {
        base = '$home/.cache/$app';
      } else {
        throw StateError('Neither XDG_CACHE_HOME nor HOME is set.');
      }
  }
  return Directory(base);
}

/// A file-name-safe key for [source] (a URL), bounded so it is short enough
/// on every filesystem. The tail of the URL is what tells entries apart.
String cacheFileKey(String source) {
  final key = base64Url.encode(utf8.encode(source)).replaceAll('=', '');
  return key.length > 100 ? key.substring(key.length - 100) : key;
}

/// Wraps a [CatalogFetcher] with an on-disk copy of the last good response.
///
/// A successful fetch refreshes the cache. If the fetch fails with
/// [CatalogUnavailable] and a cached copy exists, the copy is served and
/// [servedStale] is true, so the hub still works offline. The failure is
/// rethrown when there is no cache. A cache that cannot be read or written
/// never breaks a load; the cache is an optimisation, not a source of truth.
class CatalogCache {
  final Directory directory;
  final CatalogFetcher _fetch;

  /// True when the most recent [fetch] fell back to the cached copy.
  bool servedStale = false;

  /// The error that caused the most recent stale fallback, for reporting.
  CatalogUnavailable? lastFetchError;

  CatalogCache(this.directory, {CatalogFetcher? fetch})
    : _fetch = fetch ?? httpGetCatalog;

  File _file(Uri uri) => File(
    '${directory.path}${Platform.pathSeparator}'
    'catalog-${cacheFileKey(uri.toString())}.json',
  );

  Future<String> fetch(Uri uri) async {
    try {
      final body = await _fetch(uri);
      servedStale = false;
      lastFetchError = null;
      await _write(uri, body);
      return body;
    } on CatalogUnavailable catch (e) {
      final cached = await readCached(uri);
      if (cached == null) rethrow;
      servedStale = true;
      lastFetchError = e;
      return cached;
    }
  }

  /// The last good response for [uri], or null if there is none or it cannot
  /// be read.
  Future<String?> readCached(Uri uri) async {
    try {
      final file = _file(uri);
      return await file.exists() ? await file.readAsString() : null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _write(Uri uri, String body) async {
    try {
      await directory.create(recursive: true);
      final file = _file(uri);
      // Write then rename so a crash never leaves a half-written cache.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(body, flush: true);
      await tmp.rename(file.path);
    } on FileSystemException {
      // Read-only or full disk: the load itself still succeeded.
    }
  }
}
