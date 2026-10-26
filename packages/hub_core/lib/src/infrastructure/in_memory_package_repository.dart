import '../application/package_repository.dart';
import '../domain/software_package.dart';
import 'sample_catalog.dart';

class InMemoryPackageRepository implements PackageRepository {
  final Map<String, SoftwarePackage> _byId;
  final Duration refreshDelay;

  /// Seeds the repository with [sampleCatalog] unless [initial] is given.
  InMemoryPackageRepository({
    Iterable<SoftwarePackage>? initial,
    this.refreshDelay = const Duration(milliseconds: 1200),
  }) : _byId = {for (final p in initial ?? sampleCatalog()) p.id: p};

  @override
  Future<List<SoftwarePackage>> all() async => _byId.values.toList();

  @override
  Future<SoftwarePackage?> find(String id) async => _byId[id];

  /// New packages are listed first, existing ones keep their position.
  @override
  Future<void> save(SoftwarePackage package) async {
    if (_byId.containsKey(package.id)) {
      _byId[package.id] = package;
    } else {
      final rest = Map.of(_byId);
      _byId
        ..clear()
        ..[package.id] = package
        ..addAll(rest);
    }
  }

  @override
  Future<void> refresh() => Future.delayed(refreshDelay);
}
