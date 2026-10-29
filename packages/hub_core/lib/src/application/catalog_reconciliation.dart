import '../domain/software_package.dart';

/// How to move a catalog that is already shown to a freshly loaded one, in the
/// order the user should see it happen.
class CatalogReconciliation {
  /// Step 1: the shown packages with new text (name, description, releases)
  /// and without entries that left the catalog. Icons and local state
  /// (status, versions) are untouched, so this can be applied immediately.
  final List<SoftwarePackage> textUpdated;

  /// Step 2: entries the user does not have yet. A frontend should show each
  /// one only once its icon has loaded (or failed to).
  final List<SoftwarePackage> added;

  /// Step 3: shown entries whose icon address changed; carries the fresh
  /// package so the new [SoftwarePackage.iconUrl] can be read from it.
  final List<SoftwarePackage> iconChanged;

  /// Catalog order of the fresh load, for placing late arrivals.
  final List<String> order;

  const CatalogReconciliation({
    required this.textUpdated,
    required this.added,
    required this.iconChanged,
    required this.order,
  });
}

CatalogReconciliation reconcileCatalog(
  List<SoftwarePackage> shown,
  List<SoftwarePackage> fresh,
) {
  final freshById = {for (final p in fresh) p.id: p};
  final shownIds = {for (final p in shown) p.id};
  final textUpdated = <SoftwarePackage>[];
  final iconChanged = <SoftwarePackage>[];
  for (final current in shown) {
    final next = freshById[current.id];
    if (next == null) continue;
    textUpdated.add(
      current.copyWith(
        name: next.name,
        description: next.description,
        latestVersion: next.latestVersion,
        latestRelease: next.latestRelease,
        olderReleases: next.olderReleases,
        availableVersions: next.availableVersions,
      ),
    );
    final url = next.iconUrl;
    if (url != null && url != current.iconUrl) iconChanged.add(next);
  }
  return CatalogReconciliation(
    textUpdated: textUpdated,
    added: [
      for (final p in fresh)
        if (!shownIds.contains(p.id)) p,
    ],
    iconChanged: iconChanged,
    order: [for (final p in fresh) p.id],
  );
}
