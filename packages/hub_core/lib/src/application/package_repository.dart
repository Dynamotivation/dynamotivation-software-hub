import '../domain/software_package.dart';

/// Port: where the package catalog comes from.
abstract interface class PackageRepository {
  Future<List<SoftwarePackage>> all();

  Future<SoftwarePackage?> find(String id);

  /// Inserts or replaces the package with the same id.
  Future<void> save(SoftwarePackage package);

  /// Re-reads the catalog from its source.
  Future<void> refresh();
}

/// Optional capability of a [PackageRepository]: a catalog snapshot that is
/// available without waiting for the network, so a frontend can show something
/// at once and refresh afterwards.
abstract interface class CachedPackageSource {
  /// The last known catalog, or null if there is none. Loading it makes it the
  /// repository's current catalog; [PackageRepository.refresh] replaces it.
  Future<List<SoftwarePackage>?> cachedPackages();
}

/// Optional port: a source that serves each package's full release history
/// separately from the catalog, so the catalog stays small.
abstract interface class ReleaseHistorySource {
  /// The package with [SoftwarePackage.olderReleases] filled in. Throws
  /// [CatalogUnavailable] if the history cannot be fetched or understood.
  Future<SoftwarePackage> loadReleaseHistory(String id);
}

/// Optional capability: a repository whose install state comes from the
/// device. [rescanDevice] reads the device again and keeps the catalog it
/// holds, without a network request, e.g. after a setup ran.
abstract interface class DeviceInventorySource {
  Future<void> rescanDevice();
}
