import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

class _Processes implements ApplicationProcesses {
  Set<String> running = {};
  int scans = 0;
  @override
  Future<Set<String>> runningExecutables(Set<String> executables) async {
    scans++;
    return running.intersection(executables);
  }

  @override
  Future<void> terminateAll(String executable) async {
    running.remove(executable);
  }
}

void main() {
  testWidgets(
    'poll sees external starts/exits and stops with controller disposal',
    (tester) async {
      final package = testCatalog().first;
      final processes = _Processes();
      final controller = HubController(
        HubUseCases(
          InMemoryPackageRepository([package]),
          InMemorySettingsRepository(),
          processes: processes,
        ),
      );
      await controller.load();
      await controller.startProcessWatch();
      expect(controller.isRunning(package.id), isFalse);
      processes.running.add(package.launchExecutable);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.isRunning(package.id), isTrue);
      processes.running.clear();
      await tester.pump(const Duration(seconds: 2));
      expect(controller.isRunning(package.id), isFalse);
      processes.running.add(package.launchExecutable);
      await controller.refreshRunningProcesses();
      await controller.forceClosePackage(package.id);
      expect(controller.isRunning(package.id), isFalse);
      controller.stopProcessWatch();
      final pausedScans = processes.scans;
      processes.running.add(package.launchExecutable);
      await tester.pump(const Duration(seconds: 4));
      expect(processes.scans, pausedScans);
      await controller.startProcessWatch();
      expect(controller.isRunning(package.id), isTrue);
      controller.dispose();
      final scans = processes.scans;
      await tester.pump(const Duration(seconds: 4));
      expect(processes.scans, scans);
    },
  );
}
