import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_images/hub_images.dart';
import 'package:yaru/yaru.dart';

/// Ubuntu Yaru styled app icon tile with squircle border. Shows the catalog's
/// webp icon (cached on disk), or a neutral glyph while there is none.
class PackageIcon extends StatelessWidget {
  final SoftwarePackage package;
  final double size;

  const PackageIcon({super.key, required this.package, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: HubIcon(
          url: package.iconUrl,
          fallback: Center(
            child: Icon(YaruIcons.application, size: size * 0.6),
          ),
        ),
      ),
    );
  }
}
