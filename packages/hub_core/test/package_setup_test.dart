import 'dart:io';

import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';
import 'package:test/test.dart';

class Inventory implements InstalledApplicationRepository {
  List<InstalledApplication> apps = [];
  int scans = 0;
  @override
  Future<List<InstalledApplication>> scan() async {
    scans++;
    return apps;
  }
}

/// Stages instantly; [run] "installs" by putting [installs] into the
/// inventory and returns [exitCode].
class FakeInstaller implements SetupInstaller {
  final Inventory inventory;
  InstalledApplication? installs;
  int exitCode = 0;
  Object? stageError;
  final staged = <SetupOffer>[];
  final ran = <String>[];
  final discarded = <String>[];

  FakeInstaller(this.inventory);

  @override
  Future<String> stage(
    SetupOffer offer, {
    void Function(double progress)? onProgress,
  }) async {
    if (stageError case final e?) throw e;
    staged.add(offer);
    onProgress?.call(0.5);
    onProgress?.call(1);
    return 'staged-${offer.version}.exe';
  }

  @override
  Future<int> run(String stagedFile, {required String logFile}) async {
    ran.add(stagedFile);
    if (installs case final app?) {
      inventory.apps = [
        for (final a in inventory.apps)
          if (a.id != app.id) a,
        app,
      ];
    }
    return exitCode;
  }

  /// Removes the app from the inventory unless [uninstallRemoves] is false.
  final uninstalled = <String>[];
  bool uninstallRemoves = true;

  @override
  Future<int> uninstall(String uninstaller, {required String logFile}) async {
    uninstalled.add(uninstaller);
    if (uninstallRemoves) inventory.apps = [];
    return exitCode;
  }

  @override
  Future<void> discard(String stagedFile) async => discarded.add(stagedFile);

  @override
  Future<void> install(String stagedFile, {required bool restart}) async {}

  @override
  Future<void> clearStaged({String? keep}) async {}
}

class MemoryLog implements InstallLog {
  final lines = <String>[];
  var closed = 0;
  @override
  Future<InstallLogSession> start(String packageId, String version) async =>
      _Session(this);
}

class _Session implements InstallLogSession {
  final MemoryLog log;
  _Session(this.log);
  @override
  String get path => 'install.log';
  @override
  String get setupLogPath => 'install.setup.log';
  @override
  Future<void> write(String line) async => log.lines.add(line);
  @override
  Future<void> close() async => log.closed++;
}

class Processes implements ApplicationProcesses {
  Set<String> running = {};
  @override
  Future<Set<String>> runningExecutables(Set<String> executables) async =>
      running.intersection(executables);
  @override
  Future<void> terminateAll(String executable) async {}
}

SoftwarePackage published(String version, {String arch = 'x64'}) =>
    SoftwarePackage(
      id: 'tool',
      name: 'Tool',
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
            arch: arch,
            url: 'https://example.com/tool-setup-$version.exe',
            sha256: 'a' * 64,
            size: 10,
          ),
        ],
      ),
      olderReleases: const [],
      availableVersions: [version],
    );

InstalledApplication installed(String version) => InstalledApplication(
  id: 'tool_is1',
  name: 'Tool',
  version: version,
  launchExecutable: r'C:\Tool\tool.exe',
  uninstallExecutable: r'C:\Tool\unins000.exe',
);

void main() {
  late Inventory inventory;
  late FakeInstaller installer;
  late MemoryLog log;
  late Processes processes;
  late HubUseCases useCases;

  void wire(String latest, {String arch = 'x64'}) {
    final repository = DevicePackageRepository(
      catalog: InMemoryPackageRepository([published(latest)]),
      installations: inventory,
      platform: 'windows',
    );
    useCases = HubUseCases(
      repository,
      InMemorySettingsRepository(),
      installer: installer,
      installLog: log,
      processes: processes,
      platform: 'windows',
      arch: arch,
      uninstallSettle: Duration.zero,
    );
  }

  setUp(() {
    inventory = Inventory();
    installer = FakeInstaller(inventory);
    log = MemoryLog();
    processes = Processes();
  });

  test('installs silently, reports progress and reads the device', () async {
    wire('2.0');
    installer.installs = installed('2.0');
    final progress = <SetupProgress>[];

    final result = await useCases.installPackage(
      'tool',
      onProgress: progress.add,
    );

    expect(result.isInstalled, isTrue);
    expect(result.currentVersion, '2.0');
    expect(installer.staged.single.url.path, '/tool-setup-2.0.exe');
    expect(installer.ran, ['staged-2.0.exe']);
    expect(installer.discarded, ['staged-2.0.exe']);
    expect(progress.whereType<SetupDownloading>().map((p) => p.fraction), [
      0,
      0.5,
      1,
    ]);
    expect(progress.last, isA<SetupRunning>());
    expect(log.lines.last, 'Done');
    expect(log.closed, 1);
    expect(useCases.isSetupRunning, isFalse);
  });

  test('updates an installed package to the latest release', () async {
    inventory.apps = [installed('1.0')];
    wire('2.0');
    installer.installs = installed('2.0');

    final result = await useCases.updatePackage('tool');

    expect(result.currentVersion, '2.0');
    expect(result.hasUpdate, isFalse);
  });

  test('a failing setup exit code is a SetupFailed with the log', () async {
    wire('2.0');
    installer.exitCode = 5;

    await expectLater(
      useCases.installPackage('tool'),
      throwsA(
        isA<SetupFailed>()
            .having((e) => e.exitCode, 'exitCode', 5)
            .having((e) => e.logPath, 'logPath', 'install.log'),
      ),
    );
    expect(installer.discarded, ['staged-2.0.exe']);
    expect(log.closed, 1);
    expect(useCases.isSetupRunning, isFalse);
  });

  test('a setup that leaves no newer version on the device failed', () async {
    inventory.apps = [installed('1.0')];
    wire('2.0');

    await expectLater(
      useCases.updatePackage('tool'),
      throwsA(isA<SetupFailed>().having((e) => e.exitCode, 'exit', isNull)),
    );
  });

  test('a running package is not updated', () async {
    inventory.apps = [installed('1.0')];
    processes.running = {r'C:\Tool\tool.exe'};
    wire('2.0');

    await expectLater(
      useCases.updatePackage('tool'),
      throwsA(isA<PackageInUse>()),
    );
    expect(installer.staged, isEmpty);
  });

  test('the domain refuses updating what has no update', () async {
    inventory.apps = [installed('2.0')];
    wire('2.0');
    await expectLater(
      useCases.updatePackage('tool'),
      throwsA(isA<PackageActionRejected>()),
    );
  });

  group('a specific version', () {
    SoftwarePackage withHistory() => published('2.0').copyWith(
      releaseCount: 3,
      olderReleases: [
        ReleaseNote(
          version: '1.5',
          date: '2026-01-01',
          highlights: const [],
          downloads: [
            DownloadLink(
              platform: 'windows',
              arch: 'x64',
              url: 'https://example.com/tool-setup-1.5.exe',
              sha256: 'b' * 64,
            ),
          ],
        ),
        const ReleaseNote(version: '1.0', date: '2025-01-01', highlights: []),
      ],
    );

    void wireHistory() {
      useCases = HubUseCases(
        DevicePackageRepository(
          catalog: InMemoryPackageRepository([withHistory()]),
          installations: inventory,
          platform: 'windows',
        ),
        InMemorySettingsRepository(),
        installer: installer,
        installLog: log,
        processes: processes,
        platform: 'windows',
        arch: 'x64',
      );
    }

    test('lists every release, marking installed and installable', () async {
      inventory.apps = [installed('2.0')];
      wireHistory();
      final choices = await useCases.releaseChoices('tool');
      expect(choices.map((c) => c.version), ['2.0', '1.5', '1.0']);
      expect(choices.map((c) => c.isInstalled), [true, false, false]);
      expect(choices.map((c) => c.installable), [true, true, false]);
      expect(choices.map((c) => c.selectable), [false, true, false]);
      expect(choices.first.isLatest, isTrue);
    });

    test('switches down to an older release, exactly', () async {
      inventory.apps = [installed('2.0')];
      wireHistory();
      installer.installs = installed('1.5');

      final result = await useCases.installVersion('tool', '1.5');

      expect(installer.staged.single.version, '1.5');
      expect(installer.staged.single.url.path, '/tool-setup-1.5.exe');
      expect(result.currentVersion, '1.5');
      expect(result.hasUpdate, isTrue);
      expect(log.lines.first, 'Switch Tool 2.0 -> 1.5');
    });

    test('a setup that leaves another version installed failed', () async {
      inventory.apps = [installed('2.0')];
      wireHistory();
      // The setup "succeeds" but the device still shows 2.0.
      await expectLater(
        useCases.installVersion('tool', '1.5'),
        throwsA(isA<SetupFailed>()),
      );
    });

    test('the installed version and unknown ones are refused', () async {
      inventory.apps = [installed('2.0')];
      wireHistory();
      await expectLater(
        useCases.installVersion('tool', '2.0'),
        throwsA(isA<PackageActionRejected>()),
      );
      await expectLater(
        useCases.installVersion('tool', '9.9'),
        throwsA(isA<PackageActionRejected>()),
      );
      await expectLater(
        useCases.installVersion('tool', '1.0'),
        throwsA(isA<PackageActionRejected>()),
      );
      expect(installer.staged, isEmpty);
    });
  });

  test('64-bit Windows installs a 32-bit x86 build', () async {
    wire('2.0', arch: 'x64');
    final repository = DevicePackageRepository(
      catalog: InMemoryPackageRepository([published('2.0', arch: 'x86')]),
      installations: inventory,
      platform: 'windows',
    );
    useCases = HubUseCases(
      repository,
      InMemorySettingsRepository(),
      installer: installer,
      installLog: log,
      processes: processes,
      platform: 'windows',
      arch: 'x64',
    );
    installer.installs = installed('2.0');
    await useCases.installPackage('tool');
    expect(installer.staged.single.setup.arch, 'x86');
  });

  test('downloads are picked by what the device runs, own arch first', () {
    DownloadLink link(String arch) =>
        DownloadLink(platform: 'windows', arch: arch, url: 'u-$arch');
    final both = [link('x86'), link('x64')];
    expect(pickSetup(both, 'windows', 'x64')?.arch, 'x64');
    expect(pickSetup(both, 'windows', 'arm64')?.arch, 'x64');
    expect(pickSetup([link('x86')], 'windows', 'arm64')?.arch, 'x86');
    expect(pickSetup([link('x64')], 'windows', 'x86'), isNull);
    expect(pickSetup([link('arm64')], 'windows', 'x64'), isNull);
    expect(pickSetup([link('')], 'windows', 'x64')?.arch, '');
    expect(pickSetup([link('x86')], 'linux', 'x64'), isNull);
  });

  test('no download for this architecture is refused', () async {
    wire('2.0', arch: 'x86');
    await expectLater(
      useCases.installPackage('tool'),
      throwsA(isA<PackageActionRejected>()),
    );
    expect(installer.staged, isEmpty);
  });

  test('a download failure reaches the caller and is logged', () async {
    wire('2.0');
    installer.stageError = SetupUnavailable(Uri(), 'offline');
    await expectLater(
      useCases.installPackage('tool'),
      throwsA(isA<SetupUnavailable>()),
    );
    expect(log.lines, contains(startsWith('Download failed')));
    expect(useCases.isSetupRunning, isFalse);
  });

  test('uninstalls silently with the registered uninstaller', () async {
    inventory.apps = [installed('2.0')];
    wire('2.0');
    final progress = <SetupProgress>[];

    final result = await useCases.uninstallPackage(
      'tool',
      onProgress: progress.add,
    );

    expect(installer.uninstalled, [r'C:\Tool\unins000.exe']);
    expect(result.isInstalled, isFalse);
    expect(progress.single, isA<SetupRunning>());
    expect(log.lines.last, 'Done');
    expect(useCases.isSetupRunning, isFalse);
  });

  test('an uninstall that leaves the app registered failed', () async {
    inventory.apps = [installed('2.0')];
    wire('2.0');
    installer.uninstallRemoves = false;
    await expectLater(
      useCases.uninstallPackage('tool'),
      throwsA(isA<SetupFailed>().having((e) => e.exitCode, 'exit', isNull)),
    );
  });

  test('a running app is not uninstalled', () async {
    inventory.apps = [installed('2.0')];
    processes.running = {r'C:\Tool\tool.exe'};
    wire('2.0');
    await expectLater(
      useCases.uninstallPackage('tool'),
      throwsA(isA<PackageInUse>()),
    );
    expect(installer.uninstalled, isEmpty);
  });

  test('only an absolute Inno uninstaller is accepted from the registry', () {
    String parse(String v) =>
        WindowsInstalledApplicationRepository.uninstallerFromCommand(v);
    expect(parse(r'"C:\Apps\Tool\unins000.exe"'), r'C:\Apps\Tool\unins000.exe');
    expect(
      parse(r'"C:\Apps\Tool\unins000.exe" /SILENT'),
      r'C:\Apps\Tool\unins000.exe',
    );
    expect(parse(r'C:\Apps\unins001.exe'), r'C:\Apps\unins001.exe');
    expect(parse('MsiExec.exe /X{1234}'), '');
    expect(parse(r'"C:\Apps\Tool\tool.exe"'), '');
    expect(parse('unins000.exe'), '');
    expect(parse(''), '');
  });

  test('FileInstallLog writes one file and folds the setup log in', () async {
    final dir = await Directory.systemTemp.createTemp('hub-log-test');
    addTearDown(() => dir.delete(recursive: true));
    final session = await FileInstallLog(dir).start('tool', '2.0');
    await session.write('hello');
    await File(session.setupLogPath).writeAsString('setup said hi');
    await session.close();

    final text = await File(session.path).readAsString();
    expect(text, contains('hello'));
    expect(text, contains('setup said hi'));
    expect(await File(session.setupLogPath).exists(), isFalse);
  });
}
