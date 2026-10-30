import '../domain/software_package.dart';

/// What a frontend should show of the catalog right now. [HubUseCases.openCatalog]
/// emits a sequence of these while the catalog settles.
class CatalogSnapshot {
  /// Everything to list, in catalog order. Includes [departing] packages.
  final List<SoftwarePackage> packages;

  /// Packages the catalog no longer lists but that are still in [packages] so
  /// the frontend can let them leave gracefully. The next snapshot drops them.
  final Set<String> departing;

  /// True while this is the last known catalog from disk and a refresh is
  /// still running.
  final bool fromCache;

  /// True for the last snapshot of the sequence.
  final bool isFinal;

  const CatalogSnapshot(
    this.packages, {
    this.departing = const {},
    this.fromCache = false,
    this.isFinal = false,
  });
}
