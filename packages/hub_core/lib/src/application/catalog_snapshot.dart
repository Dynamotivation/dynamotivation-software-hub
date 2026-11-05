import '../domain/software_package.dart';

/// What a frontend should show of the catalog right now. [HubUseCases.openCatalog]
/// emits a sequence of these while the catalog settles.
class CatalogSnapshot {
  /// Everything to list, in catalog order. Includes [departing] packages.
  /// Never contains the hub itself (see [hub]).
  final List<SoftwarePackage> packages;

  /// The hub's own catalog entry, kept apart from [packages] so it is not
  /// listed as software, counted or announced, while the self-update lookup
  /// ([HubUseCases.selfUpdateOffer]) still finds its release. Null when the
  /// catalog does not list the hub.
  final SoftwarePackage? hub;

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
    this.hub,
    this.departing = const {},
    this.fromCache = false,
    this.isFinal = false,
  });
}
