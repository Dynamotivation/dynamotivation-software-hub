import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

HubUseCases _hub() => HubUseCases(
  InMemoryPackageRepository(refreshDelay: Duration.zero),
  InMemorySettingsRepository(),
);

Future<SoftwarePackage> _register(HubUseCases hub, String name) =>
    hub.registerPackage(
      name: name,
      subtitle: 's',
      description: 'd',
      initialHighlight: 'h',
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
    final current = await _register(hub, 'Current Tool');
    expect(
      () => hub.updatePackage(current.id),
      throwsA(isA<PackageStateException>()),
    );
  });

  test('unknown package id fails with PackageNotFound', () {
    expect(_hub().updatePackage('nope'), throwsA(isA<PackageNotFound>()));
  });

  test(
    'registerPackage derives a slug id and lists the package first',
    () async {
      final hub = _hub();
      final created = await _register(hub, '  My Cool Tool! ');
      expect(created.id, 'my-cool-tool');
      expect((await hub.listPackages()).first.id, 'my-cool-tool');
    },
  );

  test('registerPackage rejects empty and duplicate names', () async {
    final hub = _hub();
    await expectLater(
      _register(hub, '  !! '),
      throwsA(isA<InvalidPackageName>()),
    );
    await _register(hub, 'Dup');
    await expectLater(
      _register(hub, 'dup'),
      throwsA(isA<PackageAlreadyRegistered>()),
    );
  });

  test('settings round-trip', () async {
    final hub = _hub();
    await hub.saveSettings(
      (await hub.loadSettings()).copyWith(themeMode: AppThemeMode.dark),
    );
    expect((await hub.loadSettings()).themeMode, AppThemeMode.dark);
  });
}
