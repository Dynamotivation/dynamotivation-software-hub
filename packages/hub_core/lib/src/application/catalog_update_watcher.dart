import '../domain/software_package.dart';
import 'hub_use_cases.dart';

/// What changed between two consecutive catalog loads, from the hub
/// user's point of view.
class CatalogUpdates {
  /// Entries that appeared in the catalog. Empty when nothing was added.
  final List<SoftwarePackage> newPackages;

  /// Entries that stayed but publish a different newest release version
  /// than before. The website lists releases newest first and versions are
  /// unique, so any difference counts, even a correction that moved the
  /// published version downwards.
  final List<SoftwarePackage> versionUpdates;

  const CatalogUpdates({
    this.newPackages = const [],
    this.versionUpdates = const [],
  });

  bool get isEmpty => newPackages.isEmpty && versionUpdates.isEmpty;
}

/// Compares two catalog loads as the catalog user experiences them:
/// completely new packages, and packages that gained a different newest
/// release. Entries that disappeared are not reported; they vanish from the
/// website without a user-facing trail worth announcing.
CatalogUpdates diffCatalog(
  List<SoftwarePackage> before,
  List<SoftwarePackage> after,
) {
  final beforeById = {for (final p in before) p.id: p};
  return CatalogUpdates(
    newPackages: [
      for (final p in after)
        if (!beforeById.containsKey(p.id)) p,
    ],
    versionUpdates: [
      for (final p in after)
        if (beforeById[p.id] case final previous? when previous.latestVersion != p.latestVersion)
          p,
    ],
  );
}

/// Tracks the catalog across scheduled polls and reports what changed.
///
/// The watcher is stateless across processes: notifications describe what
/// changed while the hub was running today. A session that starts while the
/// catalog is unavailable keeps no baseline, so the first successful poll
/// settles one instead of announcing every entry as new.
class CatalogUpdateWatcher {
  CatalogUpdateWatcher(this._useCases);

  final HubUseCases _useCases;

  List<SoftwarePackage>? _baseline;

  /// True once a baseline exists (after [poll] or [rebaseline] succeeded).
  bool get hasBaseline => _baseline != null;

  /// Runs one scheduled check: fetches the catalog from its source and
  /// reports the changes against the previous successful check. Returns
  /// null on the first successful check, which only settles the baseline.
  /// Throws [CatalogUnavailable] when the catalog cannot be fetched or
  /// parsed; the caller decides how that failure is reported and the
  /// baseline stays untouched.
  Future<CatalogUpdates?> poll() async {
    await _useCases.refreshCatalog();
    final catalog = await _useCases.listPackages();
    final previous = _baseline;
    final result = previous == null ? null : diffCatalog(previous, catalog);
    _baseline = catalog;
    return result;
  }

  /// Replaces the baseline with the currently loaded catalog without
  /// reporting anything. The frontend calls this after the user saw a
  /// refresh in the main window, so the next poll does not re-announce
  /// what was already visible on screen.
  Future<void> rebaseline() async {
    _baseline = await _useCases.listPackages();
  }
}
