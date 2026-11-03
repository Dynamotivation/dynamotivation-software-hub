import 'dart:async';

import '../domain/app_settings.dart';
import '../domain/software_package.dart';
import 'catalog_reconciliation.dart';
import 'catalog_snapshot.dart';
import 'errors.dart';
import 'icon_store.dart';
import 'package_repository.dart';
import 'self_update.dart';
import 'settings_repository.dart';

/// The operations a frontend can perform. Frontends depend on this class,
/// never on repositories or aggregate internals directly.
class HubUseCases {
  final PackageRepository _packages;
  final SettingsRepository _settings;
  final IconStore? _icons;
  final SetupInstaller? _installer;

  // ignore: prefer_initializing_formals
  HubUseCases(this._packages, this._settings, {IconStore? icons, SetupInstaller? installer})
    // ignore: prefer_initializing_formals
    : _icons = icons,
      // ignore: prefer_initializing_formals
      _installer = installer;

  Future<List<SoftwarePackage>> listPackages() => _packages.all();

  /// The last known catalog without waiting for the network, or null if the
  /// catalog source keeps none.
  Future<List<SoftwarePackage>?> cachedPackages() async {
    final source = _packages;
    return source is CachedPackageSource
        ? (source as CachedPackageSource).cachedPackages()
        : null;
  }

  /// Opens the catalog the way a user should experience it: the last known
  /// catalog at once, then the fresh one settling in behind it. Emits
  /// [CatalogSnapshot]s; the last has [CatalogSnapshot.isFinal].
  ///
  /// With a cached catalog, the steps are:
  ///  1. the cached catalog;
  ///  2. text of known packages replaced, local state kept; packages that left
  ///     the catalog stay, marked departing, for [departGrace];
  ///  3. the departed removed;
  ///  4. each new package once its icon is stored (or failed to be), and each
  ///     changed icon once the new one is stored.
  /// Without a cache the sequence is the fresh catalog alone.
  ///
  /// Errors reach the stream. One before any snapshot means there is nothing
  /// to show; one after means the refresh failed behind a catalog already on
  /// screen.
  Stream<CatalogSnapshot> openCatalog({
    Duration departGrace = const Duration(milliseconds: 300),
  }) {
    final out = StreamController<CatalogSnapshot>();
    var cancelled = false;
    out.onCancel = () => cancelled = true;
    void emit(CatalogSnapshot s) {
      if (!cancelled) out.add(s);
    }

    Future<void> run() async {
      var shown = await cachedPackages() ?? const <SoftwarePackage>[];
      final hadCache = shown.isNotEmpty;
      if (hadCache) emit(CatalogSnapshot(shown, fromCache: true));

      // Without a cache the first read is the load; with one, refresh it.
      if (hadCache) await _packages.refresh();
      final fresh = await _packages.all();
      if (!hadCache) {
        emit(CatalogSnapshot(fresh, isFinal: true));
        return;
      }

      final plan = reconcileCatalog(shown, fresh);
      final updated = {for (final p in plan.textUpdated) p.id: p};
      final leaving = {
        for (final p in shown)
          if (!updated.containsKey(p.id)) p.id,
      };
      shown = [for (final p in shown) updated[p.id] ?? p];
      emit(CatalogSnapshot(shown, departing: leaving));
      if (leaving.isNotEmpty) {
        await Future<void>.delayed(departGrace);
        shown = [
          for (final p in shown)
            if (!leaving.contains(p.id)) p,
        ];
        emit(CatalogSnapshot(shown));
      }

      Future<void> ready(String? url) async {
        if (url != null) await _icons?.prefetch(url);
      }

      await Future.wait([
        for (final p in plan.added)
          () async {
            await ready(p.iconUrl);
            shown = [...shown, p]
              ..sort(
                (a, b) => plan.order
                    .indexOf(a.id)
                    .compareTo(plan.order.indexOf(b.id)),
              );
            emit(CatalogSnapshot(shown));
          }(),
        for (final p in plan.iconChanged)
          () async {
            await ready(p.iconUrl);
            shown = [
              for (final s in shown)
                s.id == p.id ? s.copyWith(iconUrl: p.iconUrl) : s,
            ];
            emit(CatalogSnapshot(shown));
          }(),
      ]);
      emit(CatalogSnapshot(shown, isFinal: true));
    }

    run()
        .catchError((Object error, StackTrace stack) {
          if (!cancelled) out.addError(error, stack);
        })
        .whenComplete(out.close);
    return out.stream;
  }

  Future<void> refreshCatalog() => _packages.refresh();

  /// The package with its older releases fetched, for the details view. The
  /// catalog carries only the latest release; this loads the rest. A source
  /// that has no separate history returns the package as it is.
  Future<SoftwarePackage> loadReleaseHistory(String id) async {
    final source = _packages;
    if (source is ReleaseHistorySource) {
      return (source as ReleaseHistorySource).loadReleaseHistory(id);
    }
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    return package;
  }

  /// Applies the update command and returns the updated package.
  Future<SoftwarePackage> updatePackage(String id) =>
      _apply(id, (p) => p.update());

  Future<SoftwarePackage> installPackage(String id) =>
      _apply(id, (p) => p.install());

  Future<SoftwarePackage> uninstallPackage(String id) =>
      _apply(id, (p) => p.uninstall());

  /// The hub's own pending update from [packages], or null when the catalog
  /// lists no newer release for itself or offers no download for this
  /// device. [installedVersion] is the running app's release version.
  SelfUpdateOffer? selfUpdateOffer({
    required List<SoftwarePackage> packages,
    required String installedVersion,
  }) =>
      evaluateSelfUpdate(
        packages: packages,
        installedVersion: installedVersion,
      );

  /// Stages the setup of [offer] in the app's own cache and returns the
  /// staged file's path. Requires the composition root to have wired a
  /// [SetupInstaller]; without one this is a [PackageActionRejected] that
  /// says no installer is available.
  Future<String> stageSelfUpdate(SelfUpdateOffer offer, {void Function(double progress)? onProgress}) async {
    final installer = _installer;
    if (installer == null) {
      throw PackageActionRejected(
        hubPackageId,
        'No self-update installer is wired up.',
      );
    }
    return installer.stage(offer, onProgress: onProgress);
  }

  /// Runs a staged setup silently once the frontend has quit (the setup then
  /// finds no running Hub), and with [restart] opens the Hub again afterwards.
  Future<void> installSelfUpdate(String stagedFile, {required bool restart}) async {
    final installer = _installer;
    if (installer == null) {
      throw PackageActionRejected(
        hubPackageId,
        'No self-update installer is wired up.',
      );
    }
    await installer.install(stagedFile, restart: restart);
  }

  /// Deletes staged setups other than [keep], e.g. leftovers from failed
  /// or superseded updates. The app may call it once at startup; failures
  /// reach the caller.
  Future<void> clearStagedSelfUpdates({String? keep}) async {
    final installer = _installer;
    if (installer == null) return;
    await installer.clearStaged(keep: keep);
  }

  /// Runs a lifecycle command on the stored package. Domain refusals are
  /// rethrown as [PackageActionRejected] so frontends only handle [HubException].
  Future<SoftwarePackage> _apply(
    String id,
    SoftwarePackage Function(SoftwarePackage) command,
  ) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    final SoftwarePackage changed;
    try {
      changed = command(package);
    } on PackageStateException catch (e) {
      throw PackageActionRejected(id, e.message);
    }
    await _packages.save(changed);
    return changed;
  }

  Future<AppSettings> loadSettings() => _settings.load();

  Future<void> saveSettings(AppSettings settings) => _settings.save(settings);
}
