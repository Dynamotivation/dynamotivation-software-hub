import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

class _StubPackageRepository implements PackageRepository {
  _StubPackageRepository(this.packages) : refreshFails = false;

  /// Current catalog contents; tests mutate this between polls.
  List<SoftwarePackage> packages;
  bool refreshFails;

  @override
  Future<List<SoftwarePackage>> all() async => packages;

  @override
  Future<SoftwarePackage?> find(String id) async =>
      packages.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> save(SoftwarePackage package) async {
    packages = [package, ...packages.where((p) => p.id != package.id)];
  }

  @override
  Future<void> refresh() async {
    if (refreshFails) {
      throw CatalogUnavailable(Uri.parse('https://example.test/'), 'offline');
    }
    // The stub's contents change independently of refresh, like the real
    // website does, so each [HubUseCases] call observes them.
  }
}

SoftwarePackage _package(String id, {String? latestVersion, String name = ''}) {
  final version = latestVersion ?? '';
  return SoftwarePackage(
    id: id,
    name: name.isEmpty ? id : name,
    description: '',
    subtitle: '',
    currentVersion: '',
    latestVersion: version,
    iconAsset: '',
    status: PackageInstallationStatus.notInstalled,
    latestRelease: ReleaseNote(version: version, date: '', highlights: []),
    olderReleases: const [],
    availableVersions: version.isEmpty ? const [] : [version],
  );
}

void main() {
  test('diff reports new entries and changed newest versions', () {
    final before = [_package('a', latestVersion: '1.0'), _package('b', latestVersion: '2.0')];
    final after = [
      _package('a', latestVersion: '1.3'),
      _package('b', latestVersion: '2.0'),
      _package('c', latestVersion: '1.0'),
    ];

    final updates = diffCatalog(before, after);

    expect(updates.newPackages.map((p) => p.id), ['c']);
    expect(updates.versionUpdates.map((p) => p.id), ['a']);
  });

  test('diff reports nothing for an unchanged catalog', () {
    final catalog = [_package('a', latestVersion: '1.0')];
    expect(diffCatalog(catalog, catalog).isEmpty, isTrue);
  });

  test('diff treats an appearing release as a version change', () {
    // An entry without releases (latestVersion '') gaining its first
    // published version is an update announcement, not a modification.
    final updates = diffCatalog(
      [_package('a')],
      [_package('a', latestVersion: '1.0')],
    );
    expect(updates.newPackages, isEmpty);
    expect(updates.versionUpdates.map((p) => p.id), ['a']);
  });

  test('diff reports disappeared releases-not-yet-new entries only', () {
    // A removed entry generally is not announced; returning catalogs or
    // name changes are out of scope by design. Kept explicit here so the
    // intent is visible in one test.
    final before = [_package('a', latestVersion: '1.0')];
    final updates = diffCatalog(before, [_package('a', latestVersion: '1.0'), _package('b')]);
    expect(updates.newPackages.map((p) => p.id), ['b']);
  });

  test('first poll settles the baseline without reporting', () async {
    final repository = _StubPackageRepository([_package('a')]);
    final watcher = CatalogUpdateWatcher(
      HubUseCases(repository, InMemorySettingsRepository()),
    );
    expect(watcher.hasBaseline, isFalse);

    final updates = await watcher.poll();

    expect(updates, isNull);
    expect(watcher.hasBaseline, isTrue);
  });

  test('later polls report what the website changed since the last one', () async {
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    final watcher = CatalogUpdateWatcher(
      HubUseCases(repository, InMemorySettingsRepository()),
    );
    await watcher.poll();

    repository.packages = [
      _package('a', latestVersion: '2.0'),
      _package('b', name: 'New Tool'),
    ];

    final updates = await watcher.poll();

    expect(updates?.newPackages.single.id, 'b');
    expect(updates?.newPackages.single.name, 'New Tool');
    expect(updates?.versionUpdates.single.id, 'a');
  });

  test('a failed poll leaves the baseline untouched', () async {
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    final watcher = CatalogUpdateWatcher(
      HubUseCases(repository, InMemorySettingsRepository()),
    );
    await watcher.poll();

    repository.refreshFails = true;
    expect(watcher.poll(), throwsA(isA<CatalogUnavailable>()));
    expect(watcher.hasBaseline, isTrue);

    repository.refreshFails = false;
    final updates = await watcher.poll();
    expect(updates?.isEmpty, isTrue);
  });

  test('rebaseline absorbs the state the user already saw', () async {
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    final hub = HubUseCases(repository, InMemorySettingsRepository());
    final watcher = CatalogUpdateWatcher(hub);
    await watcher.poll();

    // The frontend window refreshed through the normal flow first.
    repository.packages = [_package('a', latestVersion: '2.0'), _package('b')];
    await hub.refreshCatalog();
    await watcher.rebaseline();

    expect((await watcher.poll())?.isEmpty, isTrue);
  });
}
