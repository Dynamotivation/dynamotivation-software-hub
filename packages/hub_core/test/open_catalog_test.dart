import 'dart:async';

import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

SoftwarePackage _pkg(String id, String name, {String? icon}) => SoftwarePackage(
  id: id,
  name: name,
  description: '',
  subtitle: '',
  currentVersion: '',
  latestVersion: '',
  iconUrl: icon,
  status: PackageInstallationStatus.notInstalled,
  latestRelease: const ReleaseNote(version: '', date: '', highlights: []),
  olderReleases: const [],
  availableVersions: const [],
);

class _Repo implements PackageRepository, CachedPackageSource {
  _Repo(this.cached, this.fresh, {this.failRefresh = false});
  final List<SoftwarePackage>? cached;
  final List<SoftwarePackage> fresh;
  final bool failRefresh;
  late List<SoftwarePackage> _current = cached ?? const [];

  @override
  Future<List<SoftwarePackage>?> cachedPackages() async => cached;
  @override
  Future<void> refresh() async {
    if (failRefresh) throw CatalogUnavailable(Uri.parse('x:'), 'offline');
    _current = fresh;
  }

  @override
  Future<List<SoftwarePackage>> all() async => _current;
  @override
  Future<SoftwarePackage?> find(String id) async => null;
  @override
  Future<void> save(SoftwarePackage package) async {}
}

/// A source with no separate cache: reading it is the load.
class _Plain implements PackageRepository {
  _Plain(this.packages);
  final List<SoftwarePackage> packages;
  @override
  Future<List<SoftwarePackage>> all() async => packages;
  @override
  Future<SoftwarePackage?> find(String id) async => null;
  @override
  Future<void> refresh() async {}
  @override
  Future<void> save(SoftwarePackage package) async {}
}

class _Icons implements IconStore {
  final gate = Completer<void>();
  final requested = <String>[];
  @override
  Future<bool> prefetch(String url) async {
    requested.add(url);
    await gate.future;
    return true;
  }
}

HubUseCases _hub(PackageRepository repo, [IconStore? icons]) =>
    HubUseCases(repo, InMemorySettingsRepository(), icons: icons);

List<String> _names(CatalogSnapshot s) => [for (final p in s.packages) p.name];

void main() {
  test(
    'cache first, then text, then new apps once their icon is stored',
    () async {
      final icons = _Icons();
      final snapshots = <CatalogSnapshot>[];
      final done = _hub(
        _Repo(
          [_pkg('a', 'Old')],
          [_pkg('a', 'New'), _pkg('b', 'Fresh', icon: 'b.webp')],
        ),
        icons,
      ).openCatalog(departGrace: Duration.zero).forEach(snapshots.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(snapshots.map(_names), [
        ['Old'],
        ['New'],
      ]);
      expect(snapshots.first.fromCache, isTrue);
      expect(icons.requested, ['b.webp']);

      icons.gate.complete();
      await done;
      expect(snapshots.last.isFinal, isTrue);
      expect(_names(snapshots.last), ['New', 'Fresh']);
    },
  );

  test('a removed app departs first, then goes', () async {
    final snapshots = await _hub(
      _Repo([_pkg('a', 'A'), _pkg('b', 'B')], [_pkg('a', 'A')]),
    ).openCatalog(departGrace: const Duration(milliseconds: 5)).toList();

    final departing = snapshots.firstWhere((s) => s.departing.isNotEmpty);
    expect(departing.departing, {'b'});
    expect(_names(departing), ['A', 'B']);
    expect(_names(snapshots.last), ['A']);
    expect(snapshots.last.departing, isEmpty);
  });

  test('without a cache the fresh catalog is the only snapshot', () async {
    final snapshots = await _hub(_Repo(null, [_pkg('a', 'A')]))
        .openCatalog()
        .toList();
    expect(snapshots, hasLength(1));
    expect(snapshots.single.isFinal, isTrue);
  });

  test('a failed refresh behind a cache surfaces as a stream error', () async {
    final snapshots = <CatalogSnapshot>[];
    final errors = <Object>[];
    final done = Completer<void>();
    _hub(_Repo([_pkg('a', 'A')], const [], failRefresh: true))
        .openCatalog()
        .listen(snapshots.add, onError: errors.add, onDone: done.complete);
    await done.future;
    expect(snapshots, hasLength(1));
    expect(errors.single, isA<CatalogUnavailable>());
  });

  group('the hub itself', () {
    SoftwarePackage hubEntry(String version) => SoftwarePackage(
      id: hubPackageId,
      name: 'Hub',
      description: '',
      subtitle: '',
      currentVersion: '',
      latestVersion: version,
      status: PackageInstallationStatus.notInstalled,
      latestRelease: ReleaseNote(
        version: version,
        date: '',
        highlights: const [],
        downloads: [
          DownloadLink(
            platform: 'windows',
            arch: 'x64',
            url: 'https://example.com/hub-setup-$version.exe',
            sha256: 'a' * 64,
            size: 1,
          ),
        ],
      ),
      olderReleases: const [],
      availableVersions: [version],
    );

    test('is not listed in any snapshot, with or without a cache', () async {
      final fresh = [_pkg('a', 'A'), hubEntry('0.2.0')];
      for (final repo in <PackageRepository>[
        _Repo([_pkg('a', 'A'), hubEntry('0.1.0')], fresh),
        _Plain(fresh),
      ]) {
        final snapshots = await _hub(repo)
            .openCatalog(departGrace: Duration.zero)
            .toList();
        for (final s in snapshots) {
          expect(s.packages.map((p) => p.id), ['a']);
        }
        expect(snapshots.last.hub?.latestVersion, '0.2.0');
      }
    });

    test('is not in listPackages or cachedPackages', () async {
      final hub = _hub(_Repo([_pkg('a', 'A'), hubEntry('0.1.0')], [_pkg('a', 'A'), hubEntry('0.1.0')]));
      expect((await hub.listPackages()).map((p) => p.id), ['a']);
      expect((await hub.cachedPackages())!.map((p) => p.id), ['a']);
    });

    test('a catalog of only the hub lists nothing', () async {
      final snapshots = await _hub(
        _Plain([hubEntry('0.1.0')]),
      ).openCatalog().toList();
      expect(snapshots.single.packages, isEmpty);
      expect(snapshots.single.hub, isNotNull);
    });

    test('self-update still finds the release hidden from the list', () async {
      final hub = _hub(_Plain([_pkg('a', 'A'), hubEntry('0.2.0')]));
      final catalog = await hub.currentCatalog();
      expect(catalog.packages.map((p) => p.id), ['a']);

      final offer = hub.selfUpdateOffer(
        packages: [?catalog.hub],
        installedVersion: '0.1.0',
        platform: 'windows',
        arch: 'x64',
      );
      expect(offer?.version, '0.2.0');
    });
  });
}
