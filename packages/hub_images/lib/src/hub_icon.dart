import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';

import 'disk_cached_image.dart';

/// Gives [HubIcon]s below it the [IconCache] to read through. Placed once,
/// above the app, by the frontend's `main.dart`.
class HubImageScope extends InheritedWidget {
  const HubImageScope({super.key, required this.icons, required super.child});

  final IconCache icons;

  static IconCache of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HubImageScope>();
    assert(scope != null, 'No HubImageScope above this HubIcon.');
    return scope!.icons;
  }

  @override
  bool updateShouldNotify(HubImageScope oldWidget) => icons != oldWidget.icons;
}

/// A catalog icon, or [fallback] while there is none or it cannot be loaded.
/// Bitmaps use [FilterQuality.high]; the default aliases visibly when a large
/// icon is shrunk.
class HubIcon extends StatelessWidget {
  const HubIcon({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) return fallback;
    return Image(
      image: DiskCachedImage(url, HubImageScope.of(context)),
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
