import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

SoftwarePackage _pkg(String id, String name) => SoftwarePackage(
  id: id,
  name: name,
  description: '',
  subtitle: '',
  currentVersion: '',
  latestVersion: '',
  status: PackageInstallationStatus.notInstalled,
  latestRelease: const ReleaseNote(version: '', date: '', highlights: []),
  olderReleases: const [],
  availableVersions: const [],
);

class _Repo implements PackageRepository, CachedPackageSource {
  _Repo(this.cached, this.fresh);
  final List<SoftwarePackage> cached;
  final List<SoftwarePackage> fresh;
  late List<SoftwarePackage> _current = cached;

  @override
  Future<List<SoftwarePackage>?> cachedPackages() async => cached;
  @override
  Future<void> refresh() async => _current = fresh;
  @override
  Future<List<SoftwarePackage>> all() async => _current;
  @override
  Future<SoftwarePackage?> find(String id) async => null;
  @override
  Future<void> save(SoftwarePackage package) async {}
}

HubController _controller(_Repo repo, {void Function()? onSynced}) =>
    HubController(
      HubUseCases(repo, InMemorySettingsRepository()),
      onStartupSynced: onSynced,
      departDuration: const Duration(milliseconds: 20),
    );

void main() {
  test(
    'shows the cache at once and the fresh text after the refresh',
    () async {
      var synced = 0;
      final c = _controller(
        _Repo([_pkg('a', 'Old')], [_pkg('a', 'New')]),
        onSynced: () => synced++,
      );
      await c.load();
      expect(c.packages.map((p) => p.name), ['Old']);
      expect(synced, 0);

      await c.revalidation;
      expect(c.packages.map((p) => p.name), ['New']);
      expect(synced, 1);
    },
  );

  test(
    'a removed selected app fades out and hands selection to its neighbour',
    () async {
      final c = _controller(
        _Repo(
          [_pkg('a', 'A'), _pkg('b', 'B'), _pkg('c', 'C')],
          [_pkg('a', 'A'), _pkg('c', 'C')],
        ),
      );
      await c.load(preferredId: 'b');

      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(c.departingIds, {'b'});
      expect(c.packages.map((p) => p.id), ['a', 'b', 'c']);

      await c.revalidation;
      expect(c.departingIds, isEmpty);
      expect(c.packages.map((p) => p.id), ['a', 'c']);
      expect(c.selected?.id, 'c');
    },
  );
}
