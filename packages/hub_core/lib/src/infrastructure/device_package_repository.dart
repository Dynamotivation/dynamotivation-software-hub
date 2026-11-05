import '../application/errors.dart';
import '../application/installed_application_repository.dart';
import '../application/package_repository.dart';
import '../domain/installed_application.dart';
import '../domain/software_package.dart';

/// Combines an independent device inventory with platform-scoped catalog data.
/// Installation truth always comes from the device, including after refresh.
class DevicePackageRepository
    implements PackageRepository, CachedPackageSource, ReleaseHistorySource {
  final PackageRepository catalog;
  final InstalledApplicationRepository installations;

  /// An open platform id from the website registry, not an OS enum.
  final String platform;
  final Set<String> excludedPackageIds;
  List<InstalledApplication>? _installed;
  List<SoftwarePackage>? _current;

  DevicePackageRepository({
    required this.catalog,
    required this.installations,
    required this.platform,
    this.excludedPackageIds = const {},
  });

  Future<List<InstalledApplication>> _inventory() async =>
      _installed ??= await installations.scan();

  @override
  Future<List<SoftwarePackage>?> cachedPackages() async {
    final installed = await _inventory();
    final source = catalog;
    final cached = source is CachedPackageSource
        ? await (source as CachedPackageSource).cachedPackages()
        : null;
    if (cached == null && installed.isEmpty) return null;
    return _current = _merge(cached ?? [], installed);
  }

  @override
  Future<List<SoftwarePackage>> all() async =>
      _current ??= _merge(await catalog.all(), await _inventory());

  @override
  Future<SoftwarePackage?> find(String id) async =>
      (await all()).where((p) => p.id == id).firstOrNull;

  @override
  Future<void> refresh() async {
    // Do not replace a last good inventory with an empty one on scan failure.
    final installed = await installations.scan();
    _installed = installed;
    if (_current != null) {
      _current = _merge(await _catalogSnapshot(), installed);
    }
    await catalog.refresh();
    _current = _merge(await catalog.all(), installed);
  }

  Future<List<SoftwarePackage>> _catalogSnapshot() async {
    // A local-only snapshot must not initiate a network request before refresh.
    final source = catalog;
    if (source is CachedPackageSource) {
      return await (source as CachedPackageSource).cachedPackages() ?? [];
    }
    return catalog.all();
  }

  @override
  Future<void> save(SoftwarePackage package) async {
    throw PackageActionRejected(
      package.id,
      'Device inventory is read-only; package management is not implemented.',
    );
  }

  @override
  Future<SoftwarePackage> loadReleaseHistory(String id) async {
    final current = await find(id);
    if (current == null) throw PackageNotFound(id);
    final source = catalog;
    if (!current.hasUnloadedHistory || source is! ReleaseHistorySource) {
      return current;
    }
    await (source as ReleaseHistorySource).loadReleaseHistory(id);
    _current = _merge(await catalog.all(), await _inventory());
    return (await find(id)) ?? current;
  }

  List<SoftwarePackage> _merge(
    List<SoftwarePackage> published,
    List<InstalledApplication> installed,
  ) {
    final remaining = {for (final app in installed) app.id: app};
    final result = <SoftwarePackage>[];
    for (final package in published) {
      if (excludedPackageIds.contains(package.id) ||
          !package.supportsPlatform(platform)) {
        continue;
      }
      final matches = remaining.values
          .where(
            (app) =>
                _name(app.name) == _name(package.name) ||
                _name(app.name) == _name(package.id),
          )
          .toList();
      // Matching is deliberately exact after punctuation/case normalization.
      // Installations without a matching catalog name stay local.
      final match = matches.firstOrNull;
      for (final app in matches) {
        remaining.remove(app.id);
      }
      result.add(
        package.withInstallation(
          match?.version,
          platform: platform,
          executable: match?.launchExecutable ?? '',
        ),
      );
    }
    for (final app in remaining.values) {
      result.add(
        SoftwarePackage(
          id: 'local-$platform:${app.id}',
          name: app.name,
          description: '',
          subtitle: '',
          currentVersion: app.version,
          launchExecutable: app.launchExecutable,
          latestVersion: '',
          status: PackageInstallationStatus.installed,
          latestRelease: const ReleaseNote(
            version: '',
            date: '',
            highlights: [],
          ),
          olderReleases: const [],
          availableVersions: const [],
          platformIds: [platform],
          deviceObserved: true,
        ),
      );
    }
    return result;
  }

  static String _name(String value) =>
      value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
}
