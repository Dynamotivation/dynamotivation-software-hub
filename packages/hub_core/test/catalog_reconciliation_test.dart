import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

SoftwarePackage _pkg(
  String id, {
  String name = 'N',
  String? icon,
  PackageInstallationStatus status = PackageInstallationStatus.notInstalled,
}) => SoftwarePackage(
  id: id,
  name: name,
  description: '',
  subtitle: '',
  currentVersion: '',
  latestVersion: '',
  iconAsset: '',
  iconUrl: icon,
  status: status,
  latestRelease: const ReleaseNote(version: '', date: '', highlights: []),
  olderReleases: const [],
  availableVersions: const [],
);

void main() {
  test('swaps text, keeps icon and local state, drops removed entries', () {
    final plan = reconcileCatalog(
      [
        _pkg('a', icon: 'old', status: PackageInstallationStatus.installed),
        _pkg('gone'),
      ],
      [_pkg('a', name: 'Renamed', icon: 'new')],
    );
    expect(plan.textUpdated.map((p) => p.id), ['a']);
    expect(plan.textUpdated.single.name, 'Renamed');
    expect(plan.textUpdated.single.iconUrl, 'old');
    expect(plan.textUpdated.single.status, PackageInstallationStatus.installed);
    expect(plan.iconChanged.single.iconUrl, 'new');
    expect(plan.added, isEmpty);
  });

  test('reports new entries and the fresh catalog order', () {
    final plan = reconcileCatalog([_pkg('b')], [_pkg('a'), _pkg('b')]);
    expect(plan.added.map((p) => p.id), ['a']);
    expect(plan.order, ['a', 'b']);
    expect(plan.iconChanged, isEmpty);
  });
}
