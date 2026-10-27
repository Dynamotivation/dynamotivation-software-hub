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

  Future<void> refreshCatalog() => _packages.refresh();

  /// Applies the update command and returns the updated package.
  Future<SoftwarePackage> updatePackage(String id) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    final updated = package.update();
    await _packages.save(updated);
    return updated;
  }

  Future<SoftwarePackage> installPackage(String id) =>
      _apply(id, (p) => p.install());

  Future<SoftwarePackage> uninstallPackage(String id) =>
      _apply(id, (p) => p.uninstall());

  Future<SoftwarePackage> _apply(
    String id,
    SoftwarePackage Function(SoftwarePackage) command,
  ) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    final changed = command(package);
    await _packages.save(changed);
    return changed;
  }

  Future<AppSettings> loadSettings() => _settings.load();

  Future<void> saveSettings(AppSettings settings) => _settings.save(settings);
}
