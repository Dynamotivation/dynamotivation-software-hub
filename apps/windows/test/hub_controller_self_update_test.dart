import 'package:flutter/foundation.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

final _catalogUri = Uri.parse('https://dynamotivation.com/v1/catalog.json/');

const _catalog = '''
{"software": [
  {"name": "Dynamotivation Software Hub", "url": "https://dynamotivation.com/portfolio/software/dynamotivation-software-hub/",
   "release_count": 2,
   "releases": [{"version": "0.2.0", "date": "2026-11-03", "highlights": [],
     "downloads": [{"platform": "windows", "arch": "x64",
        "url": "https://example.com/dynamotivation-software-hub-setup-0.2.0.exe",
        "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "size": 10}]}]},
  {"name": "Other Tool", "url": "https://dynamotivation.com/portfolio/software/other-tool/",
   "release_count": 1,
   "releases": [{"version": "1.0.0", "date": "2026-11-01", "highlights": [], "downloads": []}]}
]}
''';

/// Records each command instead of touching the disk.
class RecordingInstaller implements SetupInstaller {
  final List<String> stages = [];
  final List<({String file, bool restart})> installs = [];

  @override
  Future<String> stage(
    SetupOffer offer, {
    void Function(double progress)? onProgress,
  }) async {
    stages.add(offer.version);
    onProgress?.call(0.4);
    onProgress?.call(1.0);
    return r'C:\staged\setup-%s.exe'.replaceFirst('%s', offer.version);
  }

  @override
  Future<void> install(String stagedFile, {required bool restart}) async {
    installs.add((file: stagedFile, restart: restart));
  }

  @override
  Future<void> clearStaged({String? keep}) async {}

  @override
  Future<int> run(String stagedFile, {required String logFile}) async => 0;

  @override
  Future<int> uninstall(String uninstaller, {required String logFile}) async =>
      0;

  @override
  Future<void> discard(String stagedFile) async {}
}

class _FailingInstaller extends RecordingInstaller {
  @override
  Future<String> stage(
    SetupOffer offer, {
    void Function(double progress)? onProgress,
  }) {
    stages.add(offer.version);
    throw SetupUnavailable(
      Uri.parse('https://blocked.invalid/setup.exe'),
      'offline',
    );
  }
}

Future<HubController> _controller(
  RecordingInstaller installer, {
  String selfVersion = '0.1.0',
  bool autoUpdates = true,
}) async {
  final settings = InMemorySettingsRepository();
  await settings.save(AppSettings(autoCheckUpdates: autoUpdates));
  return HubController(
    HubUseCases(
      WebsitePackageRepository(_catalogUri, fetch: (uri) async => _catalog),
      settings,
      installer: installer,
    ),
    selfVersion: selfVersion,
    selfPlatform: 'windows',
    selfArch: 'x64',
  );
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'a newer hub release downloads in the background and becomes ready',
    () async {
      final installer = RecordingInstaller();
      final c = await _controller(installer);
      await c.load();
      await _settle();

      expect(c.hubUpdate!.version, '0.2.0');
      expect(installer.stages, ['0.2.0']);
      expect(c.isHubUpdateReady, isTrue);
      expect(
        installer.installs,
        isEmpty,
      ); // nothing installs until asked or closed
    },
  );

  test(
    'the hub is not listed as software but its update is still found',
    () async {
      final c = await _controller(RecordingInstaller());
      await c.load();
      await _settle();

      expect(c.packages.map((p) => p.name), ['Other Tool']);
      expect(c.hubUpdate!.version, '0.2.0');

      // The same after a manual refresh and after a background sync.
      await c.refresh();
      expect(c.packages.map((p) => p.name), ['Other Tool']);
      expect(c.hubUpdate!.version, '0.2.0');
      await c.syncFromSource();
      expect(c.packages.map((p) => p.name), ['Other Tool']);
      expect(c.hubUpdate!.version, '0.2.0');
    },
  );

  test(
    'with automatic updates off nothing downloads until the user asks',
    () async {
      final installer = RecordingInstaller();
      final c = await _controller(installer, autoUpdates: false);
      await c.load();
      await _settle();
      expect(c.hubUpdate, isNotNull);
      expect(installer.stages, isEmpty);
      expect(c.isHubUpdateReady, isFalse);

      var quit = 0;
      c.quitForUpdate = () async => quit++;
      await c.updateHub();
      expect(installer.stages, ['0.2.0']);
      expect(installer.installs.single.restart, isTrue);
      expect(quit, 1);
    },
  );

  test(
    'restart to update installs the staged setup and reopens the hub once',
    () async {
      final installer = RecordingInstaller();
      final c = await _controller(installer);
      await c.load();
      await _settle();

      var quit = 0;
      c.quitForUpdate = () async => quit++;
      await c.updateHub();

      expect(installer.stages, ['0.2.0']); // no second download
      expect(installer.installs.single.restart, isTrue);
      expect(installer.installs.single.file, contains('0.2.0'));
      expect(quit, 1);

      // Quitting runs the exit hook too; the update must not be started twice.
      await c.installStagedOnExit();
      expect(installer.installs, hasLength(1));
    },
  );

  test(
    'closing the hub with a downloaded update installs it, without reopening',
    () async {
      final installer = RecordingInstaller();
      final c = await _controller(installer);
      await c.load();
      await _settle();

      await c.installStagedOnExit();
      expect(installer.installs, hasLength(1));
      expect(installer.installs.single.restart, isFalse);

      await c.installStagedOnExit();
      expect(installer.installs, hasLength(1));
    },
  );

  test('closing without a downloaded update installs nothing', () async {
    final installer = RecordingInstaller();
    final c = await _controller(installer, autoUpdates: false);
    await c.load();
    await c.installStagedOnExit();
    expect(installer.installs, isEmpty);
  });

  test(
    'a failed background download is reported, not retried, and not ready',
    () async {
      final reported = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);

      final installer = _FailingInstaller();
      final c = await _controller(installer);
      await c.load();
      await _settle();

      expect(reported.single.exception, isA<SetupUnavailable>());
      expect(c.isHubUpdateReady, isFalse);
      expect(c.hubUpdate, isNotNull); // still offered
      c.select(c.packages.first);
      await _settle();
      expect(installer.stages, hasLength(1)); // no retry loop
    },
  );

  test(
    'pressing restart after a failed download surfaces the error and stays',
    () async {
      final previous = FlutterError.onError;
      FlutterError.onError = (_) {};
      addTearDown(() => FlutterError.onError = previous);

      final c = await _controller(_FailingInstaller());
      await c.load();
      await _settle();

      var quit = 0;
      c.quitForUpdate = () async => quit++;
      await expectLater(c.updateHub(), throwsA(isA<SetupUnavailable>()));
      expect(quit, 0);
    },
  );

  test('a current install offers no update', () async {
    final installer = RecordingInstaller();
    final c = await _controller(installer, selfVersion: '0.2.0');
    await c.load();
    await _settle();
    expect(c.hubUpdate, isNull);
    expect(c.isHubUpdateReady, isFalse);
    expect(installer.stages, isEmpty);
  });
}
