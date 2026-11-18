import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_images/hub_images.dart';
import 'package:macos_ui/macos_ui.dart';

/// Rounded app-icon tile, like a macOS app icon. Shows the catalog's webp
/// icon (cached on disk), or a neutral glyph while there is none.
///
/// [size] is the height. An icon with transparent edges is cropped to its
/// shape, keeps its own width and gets no tile, rounding or [backdrop].
class PackageIcon extends StatelessWidget {
  final SoftwarePackage package;
  final double size;

  /// Fill and shadow behind a full-square icon only.
  final Color? backdrop;
  final List<BoxShadow> shadow;

  const PackageIcon({
    super.key,
    required this.package,
    required this.size,
    this.backdrop,
    this.shadow = const [],
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.225);
    return AdaptiveHubIcon(
      url: package.iconUrl,
      height: size,
      fallback: Center(child: MacosIcon(CupertinoIcons.app, size: size * 0.6)),
      frame: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: backdrop,
          borderRadius: radius,
          boxShadow: shadow,
        ),
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }
}
