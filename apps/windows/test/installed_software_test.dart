import 'package:dynamotivation_software_hub/app.dart';
import 'package:dynamotivation_software_hub/presentation/widgets/package_detail_pane.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

import 'window_manager_mock.dart';

class _Inventory implements InstalledApplicationRepository {
  String version = '1.0.0';
  @override
  Future<List<InstalledApplication>> scan() async => [
    InstalledApplication(
      id: 'aag_is1',
      name: 'All-Out Attack Generator',
      version: version,
      launchExecutable: r'D:\Games\AAG\game.exe',
    ),
  ];
}

class _Processes implements ApplicationProcesses {
  final running = <String>{};
  @override
  Future<Set<String>> runningExecutables(Set<String> executables) async =>
      running.intersection(executables);
  @override
  Future<void> terminateAll(String executable) async => running.clear();
}

class _Launcher implements ApplicationLauncher {
  final _Processes processes;
  _Launcher(this.processes);
  final calls = <String>[];
  bool fail = false;
  @override
  Future<void> launch(String executable) async {
    if (fail) throw StateError('missing executable');
    calls.add(executable);
    processes.running.add(executable);
  }
}

void main() {
  testWidgets(
    'registry state reaches status UI and background refresh updates it',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final inventory = _Inventory();
      final catalog = InMemoryPackageRepository([
        SoftwarePackage(
          id: 'all-out-attack-generator',
          name: 'All-Out Attack Generator',
          description: '',
          subtitle: '',
          currentVersion: '',
          latestVersion: '1.1.0',
          status: PackageInstallationStatus.notInstalled,
          latestRelease: const ReleaseNote(
            version: '1.1.0',
            date: '',
            highlights: [],
          ),
          olderReleases: const [],
          availableVersions: const ['1.1.0'],
          platformIds: const ['windows'],
        ),
      ], refreshDelay: Duration.zero);
      final processes = _Processes();
      final launcher = _Launcher(processes);
      final useCases = HubUseCases(
        DevicePackageRepository(
          catalog: catalog,
          installations: inventory,
          platform: 'windows',
        ),
        InMemorySettingsRepository(),
        launcher: launcher,
        processes: processes,
      );
      final controller = HubController(useCases, departDuration: Duration.zero);
      await tester.runAsync(() async {
        await controller.load();
        await controller.revalidation;
      });
      mockWindowManagerChannel();
      await tester.pumpWidget(DynamotivationApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      final update = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update to v1.1.0'),
      );
      expect(update.onPressed, isNotNull);
      expect(controller.selected!.isInstalled, isTrue);

      final launchFinder = find.widgetWithText(Button, 'Launch');
      final launch = tester.widget<Button>(launchFinder);
      expect(launch.onPressed, isNotNull);
      for (var i = 0; i < 30 && !launch.focusNode!.hasFocus; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(launch.focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(launcher.calls, [r'D:\Games\AAG\game.exe']);
      expect(controller.selected!.hasUpdate, isTrue);
      launcher.fail = true;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await tester.tap(find.text('Running'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The application could not be started. Refresh the software list and check that it is still installed.',
        ),
        findsOneWidget,
      );

      // The hourly watch refreshes repositories, then calls syncFromSource.
      inventory.version = '1.1.0';
      await tester.runAsync(() async {
        await useCases.refreshCatalog();
        await controller.syncFromSource();
      });
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PackageDetailPane),
          matching: find.text('Installed'),
        ),
        findsOneWidget,
      );
      expect(controller.selected!.currentVersion, '1.1.0');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
