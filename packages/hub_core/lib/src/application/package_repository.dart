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
