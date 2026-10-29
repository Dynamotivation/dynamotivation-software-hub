import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:hub_core/hub_core.dart';

import '../cache_locations.dart';

/// The catalog icon at [url], read from the on-disk icon cache when it is
/// there and downloaded (and stored) when it is not. Both the widget tree and
/// `preloadIcon` use this provider, so they share Flutter's in-memory cache.
///
/// Icons are webp. An icon is fetched once per URL; a changed icon must be
/// published under a new URL to be picked up.
ImageProvider hubIconImage(String url) =>
    DiskCachedImage(url, hubIconCacheDirectory);

@immutable
class DiskCachedImage extends ImageProvider<DiskCachedImage> {
  const DiskCachedImage(this.url, this.directory);

  final String url;
  final Directory directory;

  @override
  Future<DiskCachedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<DiskCachedImage>(this);

  @override
  ImageStreamCompleter loadImage(
    DiskCachedImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1.0,
      debugLabel: url,
    );
  }

  File get _file => File(
    '${directory.path}${Platform.pathSeparator}'
    '${cacheFileKey(url)}.webp',
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final file = _file;
    if (await file.exists()) {
      try {
        return await _decode(await file.readAsBytes(), decode);
      } on Exception {
        // A damaged cache entry is dropped and fetched again below.
        await _delete(file);
      }
    }
    final bytes = await _download();
    final codec = await _decode(bytes, decode);
    await _store(file, bytes);
    return codec;
  }

  Future<ui.Codec> _decode(Uint8List bytes, ImageDecoderCallback decode) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  Future<Uint8List> _download() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      final builder = BytesBuilder(copy: false);
      await response.forEach(builder.add);
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
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

  Future<void> _delete(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // Already gone or locked; the next store overwrites it.
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DiskCachedImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
