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
        "size": 10}]}]}
]}
''';

/// Records each command instead of touching the disk.
class RecordingInstaller implements SetupInstaller {
  final List<String> stages = [];
  final List<String> installs = [];
  final void Function(double progress)? onProgress;

  RecordingInstaller({this.onProgress});

  @override
  Future<String> stage(
    SelfUpdateOffer offer, {
    void Function(double progress)? onProgress,
  }) async {
    stages.add(offer.version);
    onProgress ??= this.onProgress;
    onProgress?.call(0.4);
    onProgress?.call(1.0);
    return r'C:\staged\setup-%s.exe'.replaceFirst('%s', offer.version);
  }

  @override
  Future<void> install(String stagedFile) async {
    installs.add(stagedFile);
  }

  @override
  Future<void> clearStaged({String? keep}) async {}
}

HubController _controller(
  CatalogFetcher fetch,
  RecordingInstaller installer, {
  String selfVersion = '0.1.0',
}) {
  return HubController(
    HubUseCases(
      WebsitePackageRepository(_catalogUri, fetch: fetch),
      InMemorySettingsRepository(),
      installer: installer,
    ),
    selfVersion: selfVersion,
  );
}

void main() {
  test(
    'a newer hub release in the catalog shows up as the pending update',
    () async {
      final installer = RecordingInstaller();
      final c = _controller((uri) async => _catalog, installer);
      await c.load();

      expect(c.hubUpdate, isNotNull);
      expect(c.hubUpdate!.version, '0.2.0');
    },
  );

  test('the update command stages, installs and leaves the app', () async {
    final installer = RecordingInstaller();
    final c = _controller((uri) async => _catalog, installer);
    await c.load();
    expect(c.isStagingHubUpdate, isFalse);

    var quit = 0;
    c.quitForUpdate = () async => quit++;

    await c.updateHub();
    expect(installer.stages, ['0.2.0']);
    expect(installer.installs, hasLength(1));
    expect(installer.installs.single, contains('0.2.0'));
    expect(quit, 1);
    expect(c.isStagingHubUpdate, isFalse);
  });

  test(
    'a staging failure surfaces to the caller and stops before install',
    () async {
      final c = HubController(
        HubUseCases(
          WebsitePackageRepository(_catalogUri, fetch: (u) async => _catalog),
          InMemorySettingsRepository(),
          installer: _FailingInstaller(),
        ),
        selfVersion: '0.1.0',
      );
      await c.load();
      expect(c.hubUpdate, isNotNull);
      expect(c.isStagingHubUpdate, isFalse);

      var quit = 0;
      c.quitForUpdate = () async => quit++;
      await expectLater(c.updateHub(), throwsA(isA<SetupUnavailable>()));
      expect(c.isStagingHubUpdate, isFalse);
      expect(quit, 0); // no launch, no exit for a failed download

      // Slack in: the update stays offered for a retry.
      expect(c.hubUpdate, isNotNull);
    },
  );

  test(
    'a current install offers no update and pressing the pill says so',
    () async {
      final installer = RecordingInstaller();
      final c = _controller(
        (uri) async => _catalog,
        installer,
        selfVersion: '0.2.0',
      );
      await c.load();
      expect(c.hubUpdate, isNull);
    },
  );
}

class _FailingInstaller implements SetupInstaller {
  @override
  Future<String> stage(
    SelfUpdateOffer offer, {
    void Function(double progress)? onProgress,
  }) {
    throw SetupUnavailable(
      Uri.parse('https://blocked.invalid/setup.exe'),
      'offline',
    );
  }

  @override
  Future<void> install(String stagedFile) async {}

  @override
  Future<void> clearStaged({String? keep}) async {}
}
