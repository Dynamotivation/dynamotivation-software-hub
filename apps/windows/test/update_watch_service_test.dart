import 'package:dynamotivation_software_hub/background/update_watch_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

/// Scripted watcher: poll results play back in order, startup results come
/// from [pendingResult], and what the service records is kept.
class _ScriptedWatcher extends CatalogUpdateWatcher {
  _ScriptedWatcher({this.results = const [], this.errors = const []})
    : super(HubUseCases(_NullRepository(), InMemorySettingsRepository()));

  final List<CatalogUpdates> results;
  final List<Object?> errors;
  CatalogUpdates pendingResult = const CatalogUpdates();
  int polls = 0;
  int seen = 0;
  final announced = <CatalogUpdates>[];

  @override
  Future<CatalogUpdates> poll() async {
    final error = errors[polls];
    polls += 1;
    if (error != null) throw error;
    return results[polls - 1];
  }

  @override
  Future<CatalogUpdates> pending() async => pendingResult;

  @override
  Future<void> markAnnounced(CatalogUpdates updates) async =>
      announced.add(updates);

  @override
  Future<void> markSeen() async => seen++;
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
  String get changesSummaryTitle => 'summary-title';
  @override
  String newSoftwareBody(String name) => 'new: $name';
  @override
  String updateNotificationBody(String name, String version) =>
      'update: $name $version';
  @override
  String changesSummaryBody(int count) => 'summary: $count';
}

AppSettings _settings(bool autoCheck, [bool show = true]) =>
    AppSettings(autoCheckUpdates: autoCheck, showNotifications: show);

/// Collects where each announcement went.
class _Sinks {
  _Sinks({this.focused = false});

  bool focused;
  final toasts = <String>[];
  final inApp = <String>[];

  Future<void> toast({
    required String title,
    required String body,
    String? iconUrl,
  }) async => toasts.add('$title | $body');

  void notice({required String title, required String message}) =>
      inApp.add('$title | $message');

  Future<bool> isFocused() async => focused;
}

UpdateWatchService _service(
  _ScriptedWatcher watcher,
  _Sinks sinks, {
  AppSettings? settings,
  void Function(Object, StackTrace)? onError,
  Future<void> Function()? onRefreshed,
  Duration interval = const Duration(hours: 1),
}) => UpdateWatchService(
  watcher: watcher,
  settings: () => settings ?? _settings(true),
  notify: sinks.toast,
  showInApp: sinks.notice,
  isWindowFocused: sinks.isFocused,
  texts: _FixedTexts(),
  onRefreshed: onRefreshed,
  onError: onError ?? (_, _) {},
  interval: interval,
);

CatalogUpdates _one() =>
    CatalogUpdates(newPackages: [_named('New Tool', '1.0')]);

CatalogUpdates _many() => CatalogUpdates(
  newPackages: [_named('New Tool', '1.0')],
  versionUpdates: [_named('Installed Tool', '2.0'), _named('Third', '3.0')],
);

void main() {
  test(
    'every successful fetch refreshes the window catalog before announcing',
    () async {
      final order = <String>[];
      final sinks = _Sinks();
      final service = UpdateWatchService(
        watcher: _ScriptedWatcher(results: [_one()], errors: [null]),
        settings: () => _settings(true),
        notify: ({required title, required body, String? iconUrl}) async {
          order.add('notify');
        },
        showInApp: sinks.notice,
        isWindowFocused: sinks.isFocused,
        onRefreshed: () async => order.add('refreshed'),
        texts: _FixedTexts(),
      );
      await service.check();
      expect(order, ['refreshed', 'notify']);
    },
  );

  test('a failed fetch leaves the window catalog alone', () async {
    var refreshed = 0;
    await _service(
      _ScriptedWatcher(
        results: [const CatalogUpdates()],
        errors: [StateError('offline')],
      ),
      _Sinks(),
      onRefreshed: () async => refreshed++,
    ).check();
    expect(refreshed, 0);
  });

  test('a single change is named; an unfocused window gets a toast', () async {
    final watcher = _ScriptedWatcher(results: [_one()], errors: [null]);
    final sinks = _Sinks();
    await _service(watcher, sinks).check();

    expect(sinks.toasts, ['new-title | new: New Tool']);
    expect(sinks.inApp, isEmpty);
    expect(watcher.announced.single.count, 1);
  });

  test('a single newer release is named with its version', () async {
    final watcher = _ScriptedWatcher(
      results: [
        CatalogUpdates(versionUpdates: [_named('Installed Tool', '2.0')]),
      ],
      errors: [null],
    );
    final sinks = _Sinks();
    await _service(watcher, sinks).check();
    expect(sinks.toasts, ['update-title | update: Installed Tool 2.0']);
  });

  test(
    'several changes collapse into one summary, not one toast each',
    () async {
      final watcher = _ScriptedWatcher(results: [_many()], errors: [null]);
      final sinks = _Sinks();
      await _service(watcher, sinks).check();

      expect(sinks.toasts, ['summary-title | summary: 3']);
      expect(watcher.announced.single.count, 3);
    },
  );

  test('a focused window gets an in-app notice and no toast', () async {
    final watcher = _ScriptedWatcher(results: [_many()], errors: [null]);
    final sinks = _Sinks(focused: true);
    await _service(watcher, sinks).check();

    expect(sinks.toasts, isEmpty);
    expect(sinks.inApp, ['summary-title | summary: 3']);
    expect(watcher.announced, hasLength(1));
  });

  test('nothing new announces nothing', () async {
    final watcher = _ScriptedWatcher(
      results: [const CatalogUpdates()],
      errors: [null],
    );
    final sinks = _Sinks();
    await _service(watcher, sinks).check();

    expect(sinks.toasts, isEmpty);
    expect(sinks.inApp, isEmpty);
    expect(watcher.announced, isEmpty);
  });

  test('startup announces at most one summary of what is pending', () async {
    final watcher = _ScriptedWatcher()..pendingResult = _many();
    final sinks = _Sinks();
    await _service(watcher, sinks).announceStartup();

    expect(sinks.toasts, ['summary-title | summary: 3']);
    expect(watcher.announced.single.count, 3);
  });

  test('a focused relaunch gets the startup summary in the app', () async {
    final watcher = _ScriptedWatcher()..pendingResult = _many();
    final sinks = _Sinks(focused: true);
    await _service(watcher, sinks).announceStartup();

    expect(sinks.toasts, isEmpty);
    expect(sinks.inApp, ['summary-title | summary: 3']);
  });

  test('startup with everything already announced is silent', () async {
    final watcher = _ScriptedWatcher();
    final sinks = _Sinks();
    await _service(watcher, sinks).announceStartup();

    expect(sinks.toasts, isEmpty);
    expect(sinks.inApp, isEmpty);
  });

  test('startup without automatic checks announces nothing', () async {
    final watcher = _ScriptedWatcher()..pendingResult = _many();
    final sinks = _Sinks();
    await _service(
      watcher,
      sinks,
      settings: _settings(false),
    ).announceStartup();

    expect(sinks.toasts, isEmpty);
    expect(sinks.inApp, isEmpty);
    expect(watcher.seen, 1);
  });

  test('without automatic checks nothing is fetched', () async {
    final watcher = _ScriptedWatcher(
      results: [const CatalogUpdates()],
      errors: [null],
    );
    await _service(watcher, _Sinks(), settings: _settings(false)).check();
    expect(watcher.polls, 0);
  });

  test(
    'with notifications off the catalog is fetched, nothing shown',
    () async {
      final watcher = _ScriptedWatcher(results: [_one()], errors: [null]);
      final sinks = _Sinks(focused: true);
      await _service(watcher, sinks, settings: _settings(true, false)).check();

      expect(watcher.polls, 1);
      expect(sinks.toasts, isEmpty);
      expect(sinks.inApp, isEmpty);
      // Not shown because the user turned it off: counts as known.
      expect(watcher.announced, hasLength(1));
    },
  );

  test('a failed fetch is reported and cannot announce', () async {
    final watcher = _ScriptedWatcher(
      results: [const CatalogUpdates()],
      errors: [CatalogUnavailable(Uri(), 'offline')],
    );
    final failures = <Object>[];
    final sinks = _Sinks();
    await _service(watcher, sinks, onError: (e, _) => failures.add(e)).check();

    expect(failures.single, isA<CatalogUnavailable>());
    expect(sinks.toasts, isEmpty);
  });

  test(
    'a toast that cannot be shown is reported and stays unannounced',
    () async {
      final watcher = _ScriptedWatcher(results: [_one()], errors: [null]);
      final failures = <Object>[];
      final sinks = _Sinks();
      final service = UpdateWatchService(
        watcher: watcher,
        settings: () => _settings(true),
        notify: ({required title, required body, String? iconUrl}) async =>
            throw StateError('toast refused'),
        showInApp: sinks.notice,
        isWindowFocused: sinks.isFocused,
        texts: _FixedTexts(),
        onError: (e, _) => failures.add(e),
      );
      await service.check();

      expect(failures.single, isA<StateError>());
      expect(watcher.announced, isEmpty);
    },
  );

  test('stop cancels the schedule', () async {
    final watcher = _ScriptedWatcher(
      results: [const CatalogUpdates()],
      errors: [null],
    );
    final service = _service(
      watcher,
      _Sinks(),
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
