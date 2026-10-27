import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hub_core/hub_core.dart';

/// Rounded app-icon tile, like a macOS app icon.
class PackageIcon extends StatelessWidget {
  final SoftwarePackage package;
  final double size;

  const PackageIcon({super.key, required this.package, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.225),
      child: SizedBox(
        width: size,
        height: size,
        child: package.isSvgIcon
            ? Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: SvgPicture.asset(package.iconAsset),
              )
            : Image.asset(package.iconAsset, fit: BoxFit.cover),
      ),
    );
  }
}
