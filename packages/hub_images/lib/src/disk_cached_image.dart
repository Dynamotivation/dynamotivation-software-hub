import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:hub_core/hub_core.dart';

/// The catalog icon at [url], read through [icons] (disk first, download on
/// a miss). Equal URLs share Flutter's in-memory image cache.
@immutable
class DiskCachedImage extends ImageProvider<DiskCachedImage> {
  const DiskCachedImage(this.url, this.icons);

  final String url;
  final IconCache icons;

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

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await icons.bytes(url);
    try {
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } on Exception {
      // A damaged stored icon is dropped so the next load fetches it again.
      await icons.discard(url);
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DiskCachedImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
