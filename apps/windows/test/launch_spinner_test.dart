import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

class _Inventory implements InstalledApplicationRepository {
  @override
  Future<List<InstalledApplication>> scan() async => const [
    InstalledApplication(
      id: 'tool_is1',
      name: 'Tool',
      version: '1.0',
      launchExecutable: r'C:\Tool\tool.exe',
    ),
  ];
}

class _Launcher implements ApplicationLauncher {
  bool fail = false;
  @override
  Future<void> launch(String executable) async {
    if (fail) throw StateError('missing');
  }
}

class _Processes implements ApplicationProcesses {
  Set<String> running = {};
  @override
  Future<Set<String>> runningExecutables(Set<String> executables) async =>
      running.intersection(executables);
  @override
  Future<void> terminateAll(String executable) async {}
}

void main() {
  late _Launcher launcher;
  late _Processes processes;

  HubController build() {
    launcher = _Launcher();
    processes = _Processes();
    final controller = HubController(
      HubUseCases(
        DevicePackageRepository(
          catalog: InMemoryPackageRepository(
            const [],
            refreshDelay: Duration.zero,
          ),
          installations: _Inventory(),
          platform: 'windows',
        ),
        InMemorySettingsRepository(),
        launcher: launcher,
        processes: processes,
      ),
      departDuration: Duration.zero,
    );
    return controller;
  }

  test('Launch spins until the process appears', () {
    fakeAsync((async) {
      final controller = build();
      controller.load();
      async.flushMicrotasks();
      final id = controller.packages.single.id;
      controller.select(controller.packages.single);

      controller.launchSelected();
      async.flushMicrotasks();
      expect(controller.isLaunching(id), isTrue);

      async.elapse(const Duration(seconds: 5));
      expect(controller.isLaunching(id), isTrue);

      processes.running = {r'C:\Tool\tool.exe'};
      controller.refreshRunningProcesses();
      async.flushMicrotasks();
      expect(controller.isLaunching(id), isFalse);
      expect(controller.isRunning(id), isTrue);
      controller.dispose();
    });
  });

  test('Launch gives up spinning after the timeout', () {
    fakeAsync((async) {
      final controller = build();
      controller.load();
      async.flushMicrotasks();
      final id = controller.packages.single.id;
      controller.select(controller.packages.single);

      controller.launchSelected();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 14));
      expect(controller.isLaunching(id), isTrue);
      async.elapse(const Duration(seconds: 1));
      expect(controller.isLaunching(id), isFalse);
      expect(controller.isRunning(id), isFalse);
      controller.dispose();
    });
  });

  test('a failed launch stops spinning at once', () {
    fakeAsync((async) {
      final controller = build();
      controller.load();
      async.flushMicrotasks();
      final id = controller.packages.single.id;
      controller.select(controller.packages.single);
      launcher.fail = true;

      Object? error;
      controller.launchSelected().catchError((Object e) => error = e);
      async.flushMicrotasks();
      expect(error, isA<PackageLaunchFailed>());
      expect(controller.isLaunching(id), isFalse);
      controller.dispose();
    });
  });
}
