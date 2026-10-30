import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../application/icon_store.dart';
import 'catalog_cache.dart';

/// Returns the body of a GET request, or throws.
typedef IconFetcher = Future<Uint8List> Function(Uri uri);

/// Icons on disk, one file per URL, next to the catalog cache. An icon is
/// fetched once; a changed icon must be published under a new URL.
class IconCache implements IconStore {
  final Directory directory;
  final IconFetcher _fetch;
  final Map<String, Future<Uint8List>> _inFlight = {};

  IconCache(this.directory, {IconFetcher? fetch})
    : _fetch = fetch ?? _httpGetBytes;

  File _file(String url) => File(
    '${directory.path}${Platform.pathSeparator}${cacheFileKey(url)}.webp',
  );

  /// The icon's bytes: from disk if stored, else downloaded and stored.
  /// Concurrent calls for one URL share a single download.
  Future<Uint8List> bytes(String url) =>
      _inFlight[url] ??= _load(url).whenComplete(() {
        _inFlight.remove(url);
      });

  @override
  Future<bool> prefetch(String url) async {
    try {
      await bytes(url);
      return true;
    } on Exception {
      return false;
    }
  }

  /// Forgets a stored icon, e.g. because it turned out not to decode.
  Future<void> discard(String url) async {
    try {
      await _file(url).delete();
    } on FileSystemException {
      // Already gone or locked; the next store overwrites it.
    }
  }

  Future<Uint8List> _load(String url) async {
    final file = _file(url);
    try {
      if (await file.exists()) return await file.readAsBytes();
    } on FileSystemException {
      // Unreadable entry: fetch it again.
    }
    final bytes = await _fetch(Uri.parse(url));
    await _store(file, bytes);
    return bytes;
  }

  /// Best effort: a cache that cannot be written never fails an icon.
  Future<void> _store(File file, Uint8List bytes) async {
    try {
      await directory.create(recursive: true);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    } on FileSystemException {
      // Read-only or full disk.
    }
  }
}

Future<Uint8List> _httpGetBytes(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    return builder.takeBytes();
  } finally {
    client.close(force: true);
  }
}
