import 'dart:convert';

import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

class Inventory implements InstalledApplicationRepository {
  List<InstalledApplication> apps = [];
  Object? error;
  @override
  Future<List<InstalledApplication>> scan() async {
    if (error case final e?) throw e;
    return apps;
  }
}

const app = InstalledApplication(
  id: 'aag_is1',
  name: 'All-Out Attack Generator',
  version: '1.2.0',
  launchExecutable: r'D:\Games\AAG\game.exe',
);

String catalogBody(String version, {String platform = 'windows'}) =>
    jsonEncode({
      'software': [
        {
          'name': 'All-Out-Attack Generator',
          'url': 'https://example.com/all-out-attack-generator/',
          'platforms': {
            platform: ['x86'],
          },
          'releases': [
            {'version': version},
          ],
        },
      ],
    });

void main() {
  late Inventory inventory;
  late WebsitePackageRepository catalog;
  late DevicePackageRepository repository;
  var body = catalogBody('1.3.0');
  String? cached;
  Object? networkError;

  setUp(() {
    body = catalogBody('1.3.0');
    cached = null;
    networkError = null;
    inventory = Inventory()..apps = [app];
    catalog = WebsitePackageRepository(
      Uri.parse('https://example.com/catalog'),
      readCache: (_) async => cached,
      fetch: (_) async {
        if (networkError case final e?) throw e;
        return body;
      },
    );
    repository = DevicePackageRepository(
      catalog: catalog,
      installations: inventory,
      platform: 'windows',
    );
  });

  test(
    'matches installed names, shows version and update; no duplicate',
    () async {
      final package = (await repository.all()).single;
      expect(package.id, 'all-out-attack-generator');
      expect(package.currentVersion, '1.2.0');
      expect(package.hasUpdate, isTrue);
      expect(package.deviceObserved, isTrue);
      expect(package.canLaunch, isTrue);
      expect(package.launchExecutable, app.launchExecutable);
    },
  );

  test('refresh observes external update, uninstall, and reinstall', () async {
    await repository.all();
    inventory.apps = [
      const InstalledApplication(
        id: 'aag_is1',
        name: 'All-Out Attack Generator',
        version: '1.3.0',
      ),
    ];
    await repository.refresh();
    expect(
      (await repository.all()).single.status,
      PackageInstallationStatus.installed,
    );
    inventory.apps = [];
    await repository.refresh();
    expect(
      (await repository.all()).single.status,
      PackageInstallationStatus.notInstalled,
    );
    expect((await repository.all()).single.currentVersion, isEmpty);
    inventory.apps = [app];
    await repository.refresh();
    expect((await repository.all()).single.hasUpdate, isTrue);
  });

  test(
    'cached startup reconciliation takes authoritative refreshed state',
    () async {
      cached = catalogBody('1.2.0');
      final useCases = HubUseCases(repository, InMemorySettingsRepository());
      final snapshots = await useCases
          .openCatalog(departGrace: Duration.zero)
          .toList();
      expect(snapshots.first.packages.single.hasUpdate, isFalse);
      expect(snapshots.last.packages.single.hasUpdate, isTrue);
    },
  );

  test(
    'local-only software is shown before network and survives failure',
    () async {
      networkError = CatalogUnavailable(
        Uri.parse('https://example.com'),
        'offline',
      );
      final seen = <CatalogSnapshot>[];
      final errors = <Object>[];
      await HubUseCases(repository, InMemorySettingsRepository())
          .openCatalog()
          .listen(seen.add, onError: errors.add)
          .asFuture<void>()
          .catchError((Object e) {
            errors.add(e);
          });
      expect(seen.first.packages.single.name, app.name);
      expect(seen.first.packages.single.currentVersion, app.version);
      expect(seen.first.packages.single.isInstalled, isTrue);
      expect(seen.first.packages.single.launchExecutable, app.launchExecutable);
      expect(seen.first.packages.single.latestVersion, isEmpty);
      expect(errors.single, isA<CatalogUnavailable>());
    },
  );

  test(
    'platform scope hides other OS catalog entries, keeps local apps',
    () async {
      body = catalogBody('1.3.0', platform: 'ps2');
      final packages = await repository.all();
      expect(packages.single.id, startsWith('local-windows:'));
      expect(packages.single.hasUpdate, isFalse);
      inventory.apps = [];
      await repository.refresh();
      expect(await repository.all(), isEmpty);
    },
  );

  test('hub catalog entry can be excluded independently of platform', () async {
    body = catalogBody('1.3.0')
        .replaceAll('all-out-attack-generator', 'dynamotivation-software-hub');
    inventory.apps = [];
    repository = DevicePackageRepository(
      catalog: catalog,
      installations: inventory,
      platform: 'windows',
      excludedPackageIds: {'dynamotivation-software-hub'},
    );
    expect(await repository.all(), isEmpty);
  });

  test(
    'inventory failures retain last good state and cannot simulate writes',
    () async {
      final before = (await repository.all()).single;
      inventory.error = const InstalledSoftwareUnavailable('denied');
      await expectLater(
        repository.refresh(),
        throwsA(isA<InstalledSoftwareUnavailable>()),
      );
      expect(
        (await repository.all()).single.currentVersion,
        before.currentVersion,
      );
      final useCases = HubUseCases(repository, InMemorySettingsRepository());
      await expectLater(
        useCases.updatePackage(before.id),
        throwsA(isA<PackageActionRejected>()),
      );
      expect((await repository.all()).single.hasUpdate, isTrue);
    },
  );

  test(
    'version comparison handles numeric, prerelease, and unknown versions',
    () {
      for (final pair in [
        ('1.10', '1.9.9'),
        ('1.2.0', '1.2.0-rc.1'),
        ('1.2.0.2', '1.2.0.1'),
      ]) {
        expect(
          isNewerSoftwareVersion(pair.$1, pair.$2),
          isTrue,
          reason: '$pair',
        );
      }
      for (final pair in [
        ('1.2.0+new', '1.2.0+old'),
        ('1.2', '1.2.0'),
        ('1.1', '1.2'),
        ('1.3', ''),
        ('1.3', 'unknown'),
      ]) {
        expect(
          isNewerSoftwareVersion(pair.$1, pair.$2),
          isFalse,
          reason: '$pair',
        );
      }
    },
  );
}
