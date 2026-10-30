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
}
