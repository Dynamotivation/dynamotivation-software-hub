import 'dart:io';

import '../application/hub_use_cases.dart';
import 'catalog_cache.dart';
import 'catalog_source.dart';
import 'icon_cache.dart';
import 'in_memory_settings_repository.dart';
import 'website_package_repository.dart';

/// Folder name under the OS per-user cache directory (see [cacheDirectory]).
const hubCacheName = 'Dynamotivation Software Hub';

/// The services every frontend runs on, wired once. A frontend's `main.dart`
/// calls [HubServices.production] and hands [useCases] to its controller; it
/// gives [icons] to its image widgets, which read stored icons through it.
class HubServices {
  final HubUseCases useCases;
  final IconCache icons;

  HubServices({required this.useCases, required this.icons});

  /// The website catalog, cached on disk, with icons cached beside it.
  /// [args] may carry `--catalog-url=<uri>`.
  factory HubServices.production(List<String> args) {
    final cache = cacheDirectory(hubCacheName);
    final catalogCache = CatalogCache(cache);
    final icons = IconCache(
      Directory('${cache.path}${Platform.pathSeparator}icons'),
    );
    return HubServices(
      useCases: HubUseCases(
        WebsitePackageRepository(
          catalogUriFromArgs(args),
          fetch: catalogCache.fetch,
          readCache: catalogCache.readCached,
        ),
        InMemorySettingsRepository(),
        icons: icons,
      ),
      icons: icons,
    );
  }
}
