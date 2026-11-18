import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_images/hub_images.dart';

/// Icon of [package] at [height]: a full-square icon sits in a tile that
/// [frame] decorates; an icon with transparent edges is cropped to its shape,
/// keeps its own width and gets no tile, border or rounded corners.
Widget packageTile(
  SoftwarePackage package,
  double height,
  Widget Function(BuildContext context, Widget child) frame,
) => AdaptiveHubIcon(
  url: package.iconUrl,
  height: height,
  fallback: const Center(child: Icon(FluentIcons.app_icon_default)),
  frame: frame,
);
