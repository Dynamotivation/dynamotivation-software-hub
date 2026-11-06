import 'dart:async';

import 'package:dynamotivation_software_hub/app.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:dynamotivation_software_hub/presentation/widgets/animated_action_width.dart';
import 'package:dynamotivation_software_hub/presentation/widgets/setup_action_button.dart';
import 'package:dynamotivation_software_hub/presentation/widgets/run_action_button.dart';
import 'package:dynamotivation_software_hub/presentation/user_date_format.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';

import 'window_manager_mock.dart';

class _Inventory implements InstalledApplicationRepository {
  String version = '1.0.0';
  bool installed = true;
  @override
  Future<List<InstalledApplication>> scan() async => [
    if (installed)
      InstalledApplication(
        id: 'aag_is1',
        name: 'All-Out Attack Generator',
        version: version,
        launchExecutable: r'D:\Games\AAG\game.exe',
        uninstallExecutable: r'D:\Games\AAG\unins000.exe',
      ),
  ];
}

/// Holds the download at half way and the setup until the test lets go.
class _GatedInstaller implements SetupInstaller {
  final _Inventory inventory;
  final download = Completer<void>();
  final setup = Completer<int>();
  _GatedInstaller(this.inventory);

  /// The version the staged setup installs: the one last staged.
  String staged = '';

  @override
  Future<String> stage(
    SetupOffer offer, {
    void Function(double progress)? onProgress,
  }) async {
    staged = offer.version;
    onProgress?.call(0.5);
    await download.future;
    onProgress?.call(1);
    return 'setup.exe';
  }

  @override
  Future<int> run(String stagedFile, {required String logFile}) async {
    final code = await setup.future;
    if (code == 0) {
      inventory
        ..installed = true
        ..version = staged;
    }
    return code;
  }

  final uninstallDone = Completer<int>();

  @override
  Future<int> uninstall(String uninstaller, {required String logFile}) async {
    final code = await uninstallDone.future;
    if (code == 0) inventory.installed = false;
    return code;
  }

  @override
  Future<void> discard(String stagedFile) async {}
  @override
  Future<void> install(String stagedFile, {required bool restart}) async {}
  @override
  Future<void> clearStaged({String? keep}) async {}
}

class _Log implements InstallLog, InstallLogSession {
  @override
  Future<InstallLogSession> start(String packageId, String version) async =>
      this;
  @override
  String get path => 'install.log';
  @override
  String get setupLogPath => 'setup.log';
  @override
  Future<void> write(String line) async {}
  @override
  Future<void> close() async {}
}

Future<(HubController, _GatedInstaller)> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1024, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  final inventory = _Inventory();
  final installer = _GatedInstaller(inventory);
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
        downloads: [
          DownloadLink(
            platform: 'windows',
            arch: 'x64',
            url: 'https://example.com/aag-setup-1.1.0.exe',
          ),
        ],
      ),
      releaseCount: 3,
      olderReleases: const [
        ReleaseNote(
          version: '0.9.0',
          date: '2025-06-01',
          highlights: [],
          downloads: [
            DownloadLink(
              platform: 'windows',
              arch: 'x86',
              url: 'https://example.com/aag-setup-0.9.0.exe',
            ),
          ],
        ),
        // Published before the website hosted downloads.
        ReleaseNote(version: '0.5.0', date: '2021-01-01', highlights: []),
      ],
      availableVersions: const ['1.1.0', '0.9.0', '0.5.0'],
      platformIds: const ['windows'],
    ),
  ], refreshDelay: Duration.zero);
  final useCases = HubUseCases(
    DevicePackageRepository(
      catalog: catalog,
      installations: inventory,
      platform: 'windows',
    ),
    InMemorySettingsRepository(),
    installer: installer,
    installLog: _Log(),
    uninstallSettle: Duration.zero,
    platform: 'windows',
    arch: 'x64',
  );
  final controller = HubController(useCases, departDuration: Duration.zero);
  await tester.runAsync(() async {
    await controller.load();
    await controller.revalidation;
  });
  mockWindowManagerChannel();
  await tester.pumpWidget(DynamotivationApp(controller: controller));
  await tester.pumpAndSettle();
  return (controller, installer);
}

void main() {
  testWidgets('update fills while downloading, locks actions, then finishes', (
    tester,
  ) async {
    final (controller, installer) = await _pump(tester);
    await tester.tap(find.text('Update to v1.1.0'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.isBusy, isTrue);
    expect(controller.operation!.downloadFraction, 0.5);
    // Both slots (Launch, Update) resize by animation, never fixed widths.
    expect(find.byType(AnimatedActionWidth), findsNWidgets(2));
    // The text is drawn on the track and on the fill, plus once invisibly
    // in the copy that sizes the progress surface.
    expect(find.text('Downloading… 50%'), findsNWidgets(3));
    expect(find.byType(SetupActionButton), findsOneWidget);
    final launch = tester.widget<Button>(
      find.ancestor(of: find.text('Launch'), matching: find.byType(Button)),
    );
    expect(launch.onPressed, isNull);

    installer.download.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Updating…'), findsNWidgets(3));
    expect(controller.operation!.downloadFraction, isNull);

    installer.setup.complete(0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(controller.isBusy, isFalse);
    expect(find.byType(SetupActionButton), findsNothing);
    expect(find.text('v1.1.0'), findsWidgets);
  });

  testWidgets('a failed setup keeps the update button and unlocks', (
    tester,
  ) async {
    final (controller, installer) = await _pump(tester);
    await tester.tap(find.text('Update to v1.1.0'));
    await tester.pump();
    installer.download.complete();
    installer.setup.complete(2);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(controller.isBusy, isFalse);
    expect(find.text('Update to v1.1.0'), findsOneWidget);
    expect(find.textContaining('install.log'), findsOneWidget);
  });

  testWidgets('uninstall runs from the overflow menu with a spinner', (
    tester,
  ) async {
    final (controller, installer) = await _pump(tester);
    await tester.tap(find.bySemanticsLabel('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uninstall').last);
    await tester.pumpAndSettle();
    // The confirmation dialog: its Uninstall button confirms.
    await tester.tap(find.widgetWithText(FilledButton, 'Uninstall'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.operation?.isUninstall, isTrue);
    expect(find.text('Uninstalling…'), findsNWidgets(3));
    final update = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Update to v1.1.0'),
    );
    expect(update.onPressed, isNull);

    installer.uninstallDone.complete(0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(controller.isBusy, isFalse);
    expect(find.text('Install v1.1.0'), findsOneWidget);
    // The menu stays for choosing a version, but offers no Uninstall.
    expect(controller.selected!.canUninstall, isFalse);
    await tester.tap(find.bySemanticsLabel('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Install another version…'), findsOneWidget);
    expect(find.text('Uninstall'), findsNothing);
  });

  testWidgets('every action state uses the one action corner radius', (
    tester,
  ) async {
    final (controller, installer) = await _pump(tester);
    const expected = BorderRadius.all(Radius.circular(8));

    /// Every corner radius drawn inside the action buttons: Fluent button
    /// surfaces (ShapeDecoration) and custom progress surfaces
    /// (BoxDecoration), visible or only keeping the size.
    List<BorderRadiusGeometry?> radii() {
      final actions = find.byWidgetPredicate(
        (w) => w is SetupActionButton || w is RunActionButton,
      );
      final out = <BorderRadiusGeometry?>[];
      for (final element
          in find
              .descendant(of: actions, matching: find.byType(AnimatedContainer))
              .evaluate()) {
        final d = (element.widget as AnimatedContainer).decoration;
        if (d is ShapeDecoration) {
          out.add(switch (d.shape) {
            RoundedRectangleBorder(:final borderRadius) => borderRadius,
            RoundedRectangleGradientBorder(:final borderRadius) => borderRadius,
            _ => null,
          });
        }
      }
      for (final element
          in find
              .descendant(of: actions, matching: find.byType(DecoratedBox))
              .evaluate()) {
        final d = (element.widget as DecoratedBox).decoration;
        if (d is BoxDecoration && d.borderRadius != null) {
          out.add(d.borderRadius);
        }
      }
      return out;
    }

    void expectAll(String state) {
      final found = radii();
      expect(found, isNotEmpty, reason: state);
      for (final r in found) {
        expect(r, expected, reason: state);
      }
    }

    expectAll('Launch + Update idle');

    await tester.tap(find.text('Update to v1.1.0'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expectAll('Update downloading');
    installer.download.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expectAll('Update running');
    installer.setup.complete(2);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uninstall').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Uninstall'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.operation?.isUninstall, isTrue);
    expectAll('Uninstalling');

    installer.uninstallDone.complete(0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expectAll('Install idle');
  });

  testWidgets('a chosen older version installs from the overflow menu', (
    tester,
  ) async {
    final (controller, installer) = await _pump(tester);
    await tester.tap(find.bySemanticsLabel('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Install another version…'));
    await tester.pumpAndSettle();

    // Every release is listed; the installed one and the one without a
    // download cannot be chosen, so Install waits for a choice.
    expect(
      find.text('Install a version of All-Out Attack Generator'),
      findsOneWidget,
    );
    Finder inDialog(Finder f) =>
        find.descendant(of: find.byType(ContentDialog), matching: f);
    expect(inDialog(find.textContaining('v1.1.0 · latest')), findsOneWidget);
    expect(
      inDialog(
        find.textContaining(
          'v0.5.0 · ${formatUserDate('2021-01-01')} · no download',
        ),
      ),
      findsOneWidget,
    );
    final radios = tester
        .widgetList<RadioButton<String>>(find.byType(RadioButton<String>))
        .toList();
    expect(radios.map((r) => r.value), ['1.1.0', '0.9.0', '0.5.0']);
    expect(radios.map((r) => r.enabled), [true, true, false]);
    final install = find.widgetWithText(FilledButton, 'Install');
    expect(tester.widget<FilledButton>(install).onPressed, isNull);

    await tester.tap(inDialog(find.textContaining('v0.9.0')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(install).onPressed, isNotNull);
    await tester.tap(install);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // An installed package shows the switch in Launch's place.
    expect(controller.operation?.isSwitchVersion, isTrue);
    expect(controller.operation?.version, '0.9.0');
    expect(find.text('Downloading… 50%'), findsWidgets);
    installer.download.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Installing v0.9.0…'), findsWidgets);

    installer.setup.complete(0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(controller.isBusy, isFalse);
    expect(controller.selected!.currentVersion, '0.9.0');
    expect(find.text('Update to v1.1.0'), findsOneWidget);
  });
}
