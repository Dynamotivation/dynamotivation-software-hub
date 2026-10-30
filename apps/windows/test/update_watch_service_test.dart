import 'package:dynamotivation_software_hub/background/update_watch_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

/// Scripted watcher: poll results play back in order.
class _ScriptedWatcher extends CatalogUpdateWatcher {
  _ScriptedWatcher({
    required this.results,
    required this.errors,
  }) : super(HubUseCases(_NullRepository(), InMemorySettingsRepository()));

  final List<CatalogUpdates?> results;
  final List<Object?> errors;
  int polls = 0;

  @override
  Future<CatalogUpdates?> poll() async {
    final error = errors[polls];
    polls += 1;
    if (error != null) throw error;
    return results[polls - 1];
  }
}

/// The script values are handed in; this repository is never reloaded.
class _NullRepository implements PackageRepository {
  @override
  Future<List<SoftwarePackage>> all() => Future.value(const []);

  @override
  Future<SoftwarePackage?> find(String id) => Future.value(null);

  @override
  Future<void> refresh() async {}

  @override
  Future<void> save(SoftwarePackage package) async {}
}

class _FixedTexts implements WatchTexts {
  @override
  String get newSoftwareTitle => 'new-title';
  @override
  String get updateNotificationTitle => 'update-title';
  @override
  String newSoftwareBody(String name) => 'new: $name';
  @override
  String updateNotificationBody(String name, String version) =>
      'update: $name $version';
}

AppSettings _settings(bool autoCheck, [bool show = true]) => AppSettings(
  autoCheckUpdates: autoCheck,
  showNotifications: show,
);

void main() {
  test('a poll with changes notifies each new entry and each newer release',
      () async {
    final watcher = _ScriptedWatcher(
      results: [
        null, // First successful check only settles the baseline.
        CatalogUpdates(
          newPackages: [_named('New Tool', '1.0')],
          versionUpdates: [_named('Installed Tool', '2.0')],
        ),
      ],
      errors: [null, null],
    );
    final shown = <String>[];
    final service = UpdateWatchService(
      watcher: watcher,
      settings: () => _settings(true),
      notify: ({required title, required body}) async {
        shown.add('$title | $body');
      },
      texts: _FixedTexts(),
    );

    await service.check();
    expect(shown, isEmpty);

    await service.check();

    expect(shown, [
      'new-title | new: New Tool',
      'update-title | update: Installed Tool 2.0',
    ]);
  });

  test('without automatic checks nothing is fetched', () async {
    final watcher = _ScriptedWatcher(results: [null], errors: [null]);
    final service = UpdateWatchService(
      watcher: watcher,
      settings: () => _settings(false),
      notify: ({required title, required body}) async {},
      texts: _FixedTexts(),
    );

    await service.check();

    expect(watcher.polls, 0);
  });

  test('with notifications off the catalog is still fetched', () async {
    final watcher = _ScriptedWatcher(
      results: [
        CatalogUpdates(
          newPackages: [_named('New Tool', '1.0')],
        ),
      ],
      errors: [null],
    );
    final shown = <String>[];
    final service = UpdateWatchService(
      watcher: watcher,
      settings: () => _settings(true, false),
      notify: ({required title, required body}) async {
        shown.add(title);
      },
      texts: _FixedTexts(),
    );

    await service.check();

    expect(watcher.polls, 1);
    expect(shown, isEmpty);
  });

  test('a failed fetch is reported and cannot announce', () async {
    final watcher = _ScriptedWatcher(
      results: [null],
      errors: [CatalogUnavailable(Uri(), 'offline')],
    );
    final failures = <Object>[];
    final shown = <String>[];
    final service = UpdateWatchService(
      watcher: watcher,
      settings: () => _settings(true),
      notify: ({required title, required body}) async {
        shown.add(title);
      },
      texts: _FixedTexts(),
      onError: (error, stack) => failures.add(error),
    );

    await service.check();

    expect(failures.single, isA<CatalogUnavailable>());
    expect(shown, isEmpty);
  });

  test('stop cancels the schedule', () async {
    final watcher = _ScriptedWatcher(results: [null], errors: [null]);
    final service = UpdateWatchService(
      watcher: watcher,
      settings: () => _settings(true),
      notify: ({required title, required body}) async {},
      texts: _FixedTexts(),
      interval: const Duration(milliseconds: 20),
    );

    service.start();
    service.stop();

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(watcher.polls, 0);
  });
}

SoftwarePackage _named(String name, String version) {
  return SoftwarePackage(
    id: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    description: '',
    subtitle: '',
    currentVersion: '',
    latestVersion: version,
    status: PackageInstallationStatus.notInstalled,
    latestRelease: ReleaseNote(version: version, date: '', highlights: []),
    olderReleases: const [],
    availableVersions: [version],
  );
}
