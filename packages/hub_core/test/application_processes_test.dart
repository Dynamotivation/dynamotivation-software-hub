import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';
import 'package:test/test.dart';

class Processes implements ApplicationProcesses {
  Set<String> running = {};
  final stopped = <String>[];
  bool fail = false;
  @override
  Future<Set<String>> runningExecutables(Set<String> executables) async {
    if (fail) throw StateError('process query failed');
    return running.intersection(executables);
  }

  @override
  Future<void> terminateAll(String executable) async {
    if (fail) throw StateError('access denied');
    stopped.add(executable);
    running.remove(executable);
  }
}

class Launcher implements ApplicationLauncher {
  final calls = <String>[];
  @override
  Future<void> launch(String executable) async {
    calls.add(executable);
  }
}

void main() {
  test(
    'running state scopes to installed paths; another instance is explicit',
    () async {
      final package = testCatalog().first;
      final processes = Processes()
        ..running = {package.launchExecutable, r'D:\Other\game.exe'};
      final launcher = Launcher();
      final useCases = HubUseCases(
        InMemoryPackageRepository([package]),
        InMemorySettingsRepository(),
        launcher: launcher,
        processes: processes,
      );
      expect(await useCases.runningPackageIds(), {package.id});
      await expectLater(
        useCases.launchPackage(package.id),
        throwsA(isA<PackageActionRejected>()),
      );
      expect(launcher.calls, isEmpty);
      await useCases.launchPackage(package.id, anotherInstance: true);
      expect(launcher.calls, [package.launchExecutable]);
      await useCases.forceClosePackage(package.id);
      expect(processes.stopped, [package.launchExecutable]);
      expect(processes.running, {r'D:\Other\game.exe'});
      expect(await useCases.runningPackageIds(), isEmpty);
      expect(package.hasUpdate, isTrue);
      processes.fail = true;
      await expectLater(
        useCases.runningPackageIds(),
        throwsA(isA<ApplicationProcessFailed>()),
      );
      await expectLater(
        useCases.forceClosePackage(package.id),
        throwsA(isA<ApplicationProcessFailed>()),
      );
    },
  );
}
