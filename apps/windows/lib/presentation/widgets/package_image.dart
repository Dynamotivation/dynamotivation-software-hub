import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';

import '../disk_cached_image.dart';

/// Icon of [package]: the bundled asset when it has one, otherwise the webp
/// icon the catalog publishes (cached on disk). Falls back to a neutral glyph
/// if it cannot be loaded.
Widget packageImage(SoftwarePackage package, BoxFit fit) {
  final url = package.iconUrl;
  if (package.iconAsset.isEmpty && url != null) {
    return Image(
      image: hubIconImage(url),
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(FluentIcons.app_icon_default)),
    );
  }
  return Image.asset(package.iconAsset, fit: fit);
}
