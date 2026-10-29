import '../domain/app_settings.dart';
import '../domain/software_package.dart';
import 'errors.dart';
import 'package_repository.dart';
import 'settings_repository.dart';

/// The operations a frontend can perform. Frontends depend on this class,
/// never on repositories or aggregate internals directly.
class HubUseCases {
  final PackageRepository _packages;
  final SettingsRepository _settings;

  HubUseCases(this._packages, this._settings);

  Future<List<SoftwarePackage>> listPackages() => _packages.all();

  /// The last known catalog without waiting for the network, or null if the
  /// catalog source keeps none.
  Future<List<SoftwarePackage>?> cachedPackages() async {
    final source = _packages;
    return source is CachedPackageSource
        ? (source as CachedPackageSource).cachedPackages()
        : null;
  }

  Future<void> refreshCatalog() => _packages.refresh();

  /// Applies the update command and returns the updated package.
  Future<SoftwarePackage> updatePackage(String id) =>
      _apply(id, (p) => p.update());

  Future<SoftwarePackage> installPackage(String id) =>
      _apply(id, (p) => p.install());

  Future<SoftwarePackage> uninstallPackage(String id) =>
      _apply(id, (p) => p.uninstall());

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
