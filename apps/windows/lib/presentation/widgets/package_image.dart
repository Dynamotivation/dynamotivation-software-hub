import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_images/hub_images.dart';

/// Icon of [package]: the webp icon the catalog publishes, or a neutral
/// glyph while there is none or it cannot be loaded.
Widget packageImage(SoftwarePackage package, BoxFit fit) => HubIcon(
  url: package.iconUrl,
  fit: fit,
  fallback: const Center(child: Icon(FluentIcons.app_icon_default)),
);
