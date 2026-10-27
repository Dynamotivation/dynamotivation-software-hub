import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

HubUseCases _hub() => HubUseCases(
  InMemoryPackageRepository(refreshDelay: Duration.zero),
  InMemorySettingsRepository(),
);

void main() {
  test(
    'updatePackage moves an outdated package to its latest version',
    () async {
      final hub = _hub();
      final outdated = (await hub.listPackages()).firstWhere(
        (p) => p.hasUpdate,
      );

      final updated = await hub.updatePackage(outdated.id);

      expect(updated.currentVersion, outdated.latestVersion);
      expect(updated.hasUpdate, isFalse);
      final stored = (await hub.listPackages()).firstWhere(
        (p) => p.id == outdated.id,
      );
      expect(stored.hasUpdate, isFalse);
    },
  );

  test('update is rejected when the package is already current', () async {
    final hub = _hub();
    final current = (await hub.listPackages()).firstWhere(
      (p) => p.isInstalled && !p.hasUpdate,
    );
    expect(
      () => hub.updatePackage(current.id),
      throwsA(isA<PackageActionRejected>()),
    );
  });

  test('unknown package id fails with PackageNotFound', () {
    expect(_hub().updatePackage('nope'), throwsA(isA<PackageNotFound>()));
  });

  test('settings round-trip', () async {
    final hub = _hub();
    await hub.saveSettings(
      (await hub.loadSettings()).copyWith(themeMode: AppThemeMode.dark),
    );
    expect((await hub.loadSettings()).themeMode, AppThemeMode.dark);
  });

  test('uninstall then install round-trips an installed package', () async {
    final hub = _hub();
    final installed = (await hub.listPackages()).firstWhere(
      (p) => p.status == PackageInstallationStatus.installed,
    );

    final removed = await hub.uninstallPackage(installed.id);
    expect(removed.isInstalled, isFalse);

    final back = await hub.installPackage(installed.id);
    expect(back.status, PackageInstallationStatus.installed);
    expect(back.currentVersion, installed.latestVersion);
  });

  test('lifecycle commands reject invalid states', () async {
    final hub = _hub();
    final all = await hub.listPackages();
    final notInstalled = all.firstWhere(
      (p) => !p.isInstalled && !p.isDownloading,
    );
    final installed = all.firstWhere((p) => p.isInstalled);

    expect(
      () => hub.uninstallPackage(notInstalled.id),
      throwsA(isA<PackageActionRejected>()),
    );
    expect(
      () => hub.installPackage(installed.id),
      throwsA(isA<PackageActionRejected>()),
    );
    expect(() => hub.installPackage('nope'), throwsA(isA<PackageNotFound>()));
  });
}
