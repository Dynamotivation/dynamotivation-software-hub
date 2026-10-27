import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';

/// Icon of [package]: the bundled asset when it has one, otherwise the icon
/// the catalog publishes. Falls back to a neutral glyph if the download fails.
Widget packageImage(SoftwarePackage package, BoxFit fit) {
  final url = package.iconUrl;
  if (package.iconAsset.isEmpty && url != null) {
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(FluentIcons.app_icon_default)),
    );
  }
  return Image.asset(package.iconAsset, fit: fit);
}
