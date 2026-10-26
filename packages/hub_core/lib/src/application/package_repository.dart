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
