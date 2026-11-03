import 'dart:io';
import 'dart:ui' as ui;

import 'package:hub_core/hub_core.dart';

/// Toast images for catalog software. The catalog serves webp, which Windows
/// toasts do not render, so each icon is converted once to a PNG file next to
/// the other caches and handed to the toast by path.
class NotificationIcons {
  NotificationIcons({required this.icons, required this.directory});

  final IconCache icons;
  final Directory directory;

  /// Absolute path of a PNG for [url], or null when there is no icon or it
  /// cannot be fetched or decoded. A toast without an image is better than no
  /// toast, so this never throws.
  Future<String?> pngPath(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final file = File(
        '${directory.path}${Platform.pathSeparator}${cacheFileKey(url)}.png',
      );
      if (await file.exists()) return file.path;
      final codec = await ui.instantiateImageCodec(await icons.bytes(url));
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      codec.dispose();
      if (png == null) return null;
      await directory.create(recursive: true);
      await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
