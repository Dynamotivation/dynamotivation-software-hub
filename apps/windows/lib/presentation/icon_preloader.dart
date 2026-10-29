import 'dart:async';

import 'package:flutter/widgets.dart';

import 'disk_cached_image.dart';

/// Completes once the icon at [url] has loaded into Flutter's image cache, or
/// has failed, or took too long. Never throws: a failed icon still gets shown
/// (as the neutral glyph from `packageImage`), the caller only waits so the
/// real icon does not pop in after its card.
Future<void> preloadIcon(String url) {
  final done = Completer<void>();
  final stream = hubIconImage(url).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish() {
    stream.removeListener(listener);
    if (!done.isCompleted) done.complete();
  }

  listener = ImageStreamListener(
    (image, synchronousCall) => finish(),
    onError: (error, stack) => finish(),
  );
  stream.addListener(listener);
  return done.future.timeout(const Duration(seconds: 15), onTimeout: finish);
}
