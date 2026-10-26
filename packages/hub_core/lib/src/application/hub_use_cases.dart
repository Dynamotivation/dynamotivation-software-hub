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

  /// Registers a locally provided package. The texts are supplied by the
  /// frontend so that they can be localized.
  Future<SoftwarePackage> registerPackage({
    required String name,
    required String subtitle,
    required String description,
    required String initialHighlight,
  }) async {
    final trimmed = name.trim();
    final id = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (id.isEmpty) throw const InvalidPackageName();
    if (await _packages.find(id) != null) throw PackageAlreadyRegistered(id);

    final package = SoftwarePackage(
      id: id,
      name: trimmed,
      subtitle: subtitle,
      description: description,
      currentVersion: '1.0.0',
      latestVersion: '1.0.0',
      iconAsset: 'assets/dynamotivation-logo.svg',
      isSvgIcon: true,
      status: PackageInstallationStatus.installed,
      latestRelease: ReleaseNote(
        version: '1.0.0',
        date: DateTime.now().toIso8601String().split('T').first,
        highlights: [initialHighlight],
      ),
      olderReleases: const [],
      availableVersions: const ['v1.0.0 (Latest)'],
    );
    await _packages.save(package);
    return package;
  }

  Future<AppSettings> loadSettings() => _settings.load();

  Future<void> saveSettings(AppSettings settings) => _settings.save(settings);
}
