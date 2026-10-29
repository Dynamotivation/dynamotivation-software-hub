import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';

/// Ubuntu Yaru styled app icon tile with squircle border.
/// Supports both SVG and raster icons, with fast Skia decoding.
class PackageIcon extends StatefulWidget {
  final SoftwarePackage package;
  final double size;

  const PackageIcon({
    super.key,
    required this.package,
    required this.size,
  });

  @override
  State<PackageIcon> createState() => _PackageIconState();
}

class _PackageIconState extends State<PackageIcon> {
  static final Map<String, ui.Image> _decodedImages = {};
  ui.Image? _decoded;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant PackageIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.package.iconAsset != widget.package.iconAsset) {
      _loadImage();
    }
  }

  void _loadImage() {
    final asset = widget.package.iconAsset;

    if (_decodedImages.containsKey(asset)) {
      _decoded = _decodedImages[asset];
      return;
    }

    for (final prefix in ['', 'assets/', 'apps/ubuntu/', 'apps/ubuntu/assets/']) {
      final file = File('$prefix$asset');
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        ui.instantiateImageCodec(bytes).then((codec) => codec.getNextFrame()).then((frame) {
          _decodedImages[asset] = frame.image;
          if (mounted) setState(() => _decoded = frame.image);
        }).catchError((_) {});
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final pkg = widget.package;

    Widget content;
    if (_decoded != null) {
      content = RawImage(
        image: _decoded,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      content = Image.asset(pkg.iconAsset, fit: BoxFit.cover);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: content,
      ),
    );
  }
}
