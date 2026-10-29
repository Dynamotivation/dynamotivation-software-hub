import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';

SoftwarePackage _pkg(String id, String name, {String? icon}) => SoftwarePackage(
  id: id,
  name: name,
  description: '',
  subtitle: '',
  currentVersion: '',
  latestVersion: '',
  iconAsset: '',
  iconUrl: icon,
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

void main() {
  test(
    'shows the cache at once, then text, then new apps after icons',
    () async {
      final iconGate = Completer<void>();
      var synced = 0;
      final controller = HubController(
        HubUseCases(
          _Repo(
            [_pkg('a', 'Old')],
            [_pkg('a', 'New'), _pkg('b', 'Fresh', icon: 'b.png')],
          ),
          InMemorySettingsRepository(),
        ),
        onCatalogSynced: () => synced++,
        departDuration: Duration.zero,
        preloadIcon: (_) => iconGate.future,
      );

      await controller.load();
      expect(controller.packages.map((p) => p.name), ['Old']);

      // Let the refresh reach the icon wait.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(controller.packages.map((p) => p.name), ['New']);
      expect(synced, 0);

      iconGate.complete();
      await controller.revalidation;
      expect(controller.packages.map((p) => p.name), ['New', 'Fresh']);
      expect(synced, 1);
    },
  );

  test(
    'a removed app fades out first and hands selection to its neighbour',
    () async {
      final controller = HubController(
        HubUseCases(
          _Repo(
            [_pkg('a', 'A'), _pkg('b', 'B'), _pkg('c', 'C')],
            [_pkg('a', 'A'), _pkg('c', 'C')],
          ),
          InMemorySettingsRepository(),
        ),
        departDuration: const Duration(milliseconds: 20),
      );
      await controller.load(preferredId: 'b');

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(controller.departingIds, {'b'});
      expect(controller.packages.map((p) => p.id), ['a', 'b', 'c']);

      await controller.revalidation;
      expect(controller.departingIds, isEmpty);
      expect(controller.packages.map((p) => p.id), ['a', 'c']);
      expect(controller.selected?.id, 'c');
    },
  );
}
