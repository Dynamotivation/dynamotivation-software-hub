import 'dart:io';

import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';
import 'package:test/test.dart';

class _Launcher implements ApplicationLauncher {
  final calls = <String>[];
  Object? error;
  @override
  Future<void> launch(String executable) async {
    if (error case final error?) throw error;
    calls.add(executable);
  }
}

void main() {
  const executable = r'D:\Games\All Out Attack\Game.exe';

  test(
    'launch starts an installed package without changing lifecycle state',
    () async {
      final launcher = _Launcher();
      final package = testCatalog().first.copyWith(
        status: PackageInstallationStatus.updateAvailable,
        currentVersion: '1.0.0',
        launchExecutable: executable,
        deviceObserved: true,
      );
      final repository = InMemoryPackageRepository([package]);
      final useCases = HubUseCases(
        repository,
        InMemorySettingsRepository(),
        launcher: launcher,
      );
      await useCases.launchPackage(package.id);
      expect(launcher.calls, [executable]);
      expect(await repository.find(package.id), same(package));
      expect(package.hasUpdate, isTrue);
    },
  );

  test(
    'unknown, uninstalled, and undiscoverable executables cannot launch',
    () async {
      final launcher = _Launcher();
      final package = testCatalog().first.copyWith(
        status: PackageInstallationStatus.notInstalled,
        launchExecutable: executable,
      );
      final repository = InMemoryPackageRepository([package]);
      final useCases = HubUseCases(
        repository,
        InMemorySettingsRepository(),
        launcher: launcher,
      );
      await expectLater(
        useCases.launchPackage('missing'),
        throwsA(isA<PackageNotFound>()),
      );
      await expectLater(
        useCases.launchPackage(package.id),
        throwsA(isA<PackageActionRejected>()),
      );
      await repository.save(
        package.copyWith(
          status: PackageInstallationStatus.installed,
          launchExecutable: '',
        ),
      );
      await expectLater(
        useCases.launchPackage(package.id),
        throwsA(isA<PackageActionRejected>()),
      );
      expect(launcher.calls, isEmpty);
    },
  );

  test('OS launch failures become typed application errors', () async {
    final launcher = _Launcher()
      ..error = const ProcessException('Game.exe', [], 'access denied');
    final package = testCatalog().first.copyWith(
      status: PackageInstallationStatus.installed,
      launchExecutable: executable,
    );
    final useCases = HubUseCases(
      InMemoryPackageRepository([package]),
      InMemorySettingsRepository(),
      launcher: launcher,
    );
    await expectLater(
      useCases.launchPackage(package.id),
      throwsA(
        isA<PackageLaunchFailed>().having(
          (error) => error.id,
          'id',
          package.id,
        ),
      ),
    );
  });

  test(
    'Windows starts EXE with its directory and no command-line parsing',
    () async {
      final calls = <(String, String)>[];
      final launcher = WindowsApplicationLauncher(
        exists: (_) async => true,
        start: (exe, cwd) async {
          calls.add((exe, cwd));
        },
      );
      await launcher.launch(executable);
      expect(calls, [(executable, r'D:\Games\All Out Attack')]);
      for (final invalid in [
        'Game.exe',
        r'D:\Games\Game.dll',
        '$executable --uninstall',
      ]) {
        await expectLater(
          launcher.launch(invalid),
          throwsA(isA<ProcessException>()),
        );
      }
      expect(calls, hasLength(1));
      final missing = WindowsApplicationLauncher(
        exists: (_) async => false,
        start: (_, _) async {
          fail('must not start a missing file');
        },
      );
      await expectLater(
        missing.launch(executable),
        throwsA(isA<ProcessException>()),
      );
    },
  );

  test('DisplayIcon supports paths, spaces, quotes and icon indices only', () {
    for (final value in [
      executable,
      '"$executable"',
      '$executable,0',
      '"$executable",-2',
    ]) {
      expect(
        WindowsInstalledApplicationRepository.executableFromDisplayIcon(value),
        executable,
      );
    }
    for (final value in [
      '',
      'Game.exe',
      r'D:\Games\icon.ico',
      r'D:\Games\unins000.exe',
      r'D:\Games\uninstall.exe',
      '"$executable" --remove',
      '$executable /silent',
    ]) {
      expect(
        WindowsInstalledApplicationRepository.executableFromDisplayIcon(value),
        isEmpty,
      );
    }
  });
}
