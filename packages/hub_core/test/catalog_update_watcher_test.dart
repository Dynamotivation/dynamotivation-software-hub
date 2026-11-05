import 'dart:io';

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
    status: PackageInstallationStatus.notInstalled,
    latestRelease: ReleaseNote(version: version, date: '', highlights: []),
    olderReleases: const [],
    availableVersions: version.isEmpty ? const [] : [version],
  );
}

void main() {
  CatalogUpdateWatcher watcherOf(
    _StubPackageRepository repository, [
    AnnouncementStore? store,
  ]) => CatalogUpdateWatcher(
    HubUseCases(repository, InMemorySettingsRepository()),
    store: store,
  );

  test('unannouncedUpdates reports new entries and unannounced versions', () {
    final updates = unannouncedUpdates(
      [
        _package('a', latestVersion: '1.3'),
        _package('b', latestVersion: '2.0'),
        _package('c', latestVersion: '1.0'),
      ],
      {
        'a': {'1.0'},
        'b': {'2.0'},
      },
    );

    expect(updates.newPackages.map((p) => p.id), ['c']);
    expect(updates.versionUpdates.map((p) => p.id), ['a']);
    expect(updates.count, 2);
  });

  test('a version that was announced once is not announced again', () {
    final updates = unannouncedUpdates(
      [_package('a', latestVersion: '1.0')],
      {'a': {'1.0', '2.0'}},
    );
    expect(updates.isEmpty, isTrue);
  });

  test('first run settles the baseline without reporting', () async {
    final store = InMemoryAnnouncementStore();
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    final watcher = watcherOf(repository, store);

    expect((await watcher.poll()).isEmpty, isTrue);
    expect(await store.load(), {'a': {'1.0'}});
  });

  test('an empty first catalog does not settle a baseline', () async {
    final store = InMemoryAnnouncementStore();
    final repository = _StubPackageRepository([]);
    final watcher = watcherOf(repository, store);
    await watcher.poll();
    expect(await store.load(), isNull);

    repository.packages = [_package('a', latestVersion: '1.0')];
    expect((await watcher.poll()).isEmpty, isTrue);
  });

  test('later polls report what changed, until it is marked announced', () async {
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    final watcher = watcherOf(repository);
    await watcher.poll();

    repository.packages = [
      _package('a', latestVersion: '2.0'),
      _package('b', name: 'New Tool'),
    ];

    final updates = await watcher.poll();
    expect(updates.newPackages.single.name, 'New Tool');
    expect(updates.versionUpdates.single.id, 'a');

    // Not marked yet (e.g. delivery failed): still pending.
    expect((await watcher.poll()).count, 2);
    await watcher.markAnnounced(updates);
    expect((await watcher.poll()).isEmpty, isTrue);
  });

  test('the announced state survives a restart', () async {
    final store = InMemoryAnnouncementStore();
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    await watcherOf(repository, store).poll();
    repository.packages = [
      _package('a', latestVersion: '2.0'),
      _package('b', latestVersion: '1.0'),
    ];
    final first = watcherOf(repository, store);
    await first.markAnnounced(await first.poll());

    // A new process: new watcher, same stored state.
    final relaunched = watcherOf(repository, store);
    expect((await relaunched.pending()).isEmpty, isTrue);

    repository.packages = [
      _package('a', latestVersion: '3.0'),
      _package('b', latestVersion: '1.0'),
    ];
    expect((await relaunched.pending()).versionUpdates.single.id, 'a');
  });

  test('a relaunch announces only what was not announced before', () async {
    final store = InMemoryAnnouncementStore();
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    await watcherOf(repository, store).poll();

    // Offline while the app was closed: three entries appear meanwhile.
    repository.packages = [
      _package('a', latestVersion: '1.1'),
      _package('b', latestVersion: '1.0'),
      _package('c', latestVersion: '1.0'),
    ];
    final relaunched = watcherOf(repository, store);
    final startup = await relaunched.pending();
    expect(startup.count, 3);
    await relaunched.markAnnounced(startup);

    expect((await watcherOf(repository, store).pending()).isEmpty, isTrue);
  });

  test('a failed poll changes nothing', () async {
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    final watcher = watcherOf(repository);
    await watcher.poll();

    repository.refreshFails = true;
    await expectLater(watcher.poll(), throwsA(isA<CatalogUnavailable>()));

    repository.refreshFails = false;
    expect((await watcher.poll()).isEmpty, isTrue);
  });

  test('markSeen absorbs the state the user already saw', () async {
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    final watcher = watcherOf(repository);
    await watcher.poll();

    repository.packages = [_package('a', latestVersion: '2.0'), _package('b')];
    await watcher.markSeen();

    expect((await watcher.poll()).isEmpty, isTrue);
  });

  test('the hub itself is never reported', () async {
    final repository = _StubPackageRepository([_package('a', latestVersion: '1.0')]);
    final watcher = watcherOf(repository);
    await watcher.poll();

    repository.packages = [
      _package('a', latestVersion: '1.0'),
      _package(hubPackageId, latestVersion: '9.9'),
    ];
    expect((await watcher.poll()).isEmpty, isTrue);
  });

  group('FileAnnouncementStore', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('hub_announced'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('round-trips the announced versions', () async {
      final store = FileAnnouncementStore(Directory('${dir.path}/nested'));
      expect(await store.load(), isNull);
      await store.save({'a': {'1.0', '2.0'}, 'b': {'0.1'}});
      expect(await FileAnnouncementStore(Directory('${dir.path}/nested')).load(), {
        'a': {'1.0', '2.0'},
        'b': {'0.1'},
      });
    });

    test('an unreadable file counts as nothing stored', () async {
      File('${dir.path}/announced.json').writeAsStringSync('{not json');
      expect(await FileAnnouncementStore(dir).load(), isNull);
      File('${dir.path}/announced.json').writeAsStringSync('[1]');
      expect(await FileAnnouncementStore(dir).load(), isNull);
    });
  });
}
