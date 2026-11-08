import 'package:hub_core/hub_core.dart';
import 'package:window_manager/window_manager.dart';

import '../platform/windows_accessibility.dart';
import '../presentation/controllers/hub_controller.dart';
import 'background_strings.dart';
import 'tray_surface.dart';
import 'update_watch_service.dart';

/// The Windows system tray icon assets: the Hub icon for a light taskbar and
/// its dark-taskbar twin (see `tool/render_tray_icons.py`).
const _trayIconLightAsset = 'assets/tray_icon.ico';
const _trayIconDarkAsset = 'assets/tray_icon_dark.ico';

/// The tray icon file for the current taskbar: the dark-taskbar icon while
/// the taskbar is dark, else the light one. [taskbarLight] null (not read
/// yet) counts as light, Windows' own default.
String trayIconAssetFor({required bool? taskbarLight}) =>
    taskbarLight == false ? _trayIconDarkAsset : _trayIconLightAsset;

/// The background half of the Windows frontend: what keeps running when the
/// hub window hides in the tray. Owns the close-button behavior, the tray
/// icon, and the hourly update watch; main.dart is the only wiring point.
///
/// The tray icon follows the taskbar's light/dark setting live. The update
/// watch stops only with the process itself (the "End" tray menu item),
/// which is exactly the point of running in the background.
class BackgroundService with WindowListener {
  BackgroundService({
    required this.controller,
    required this.tray,
    required this.watch,
    required this.strings,
    required this.accessibility,
  });

  final HubController controller;
  final TraySurface tray;
  final UpdateWatchService watch;
  final BackgroundStrings strings;

  /// Source of the taskbar's light/dark state; the tray icon follows it live.
  final WindowsAccessibility accessibility;

  /// Registers everything the surface needs while the app runs. Safe to
  /// leave running for the whole session; "End" is the only stop.
  Future<void> start() async {
    controller.addListener(_syncFromSettings);
    accessibility.taskbarLight.addListener(_syncTrayIcon);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    watch.start();
    await _syncFromSettings();
  }

  /// The tray icon exists exactly while background running is set.
  Future<void> _syncFromSettings() async {
    await accessibility.setWindowIconTheme(
      switch (controller.settings.themeMode) {
        AppThemeMode.system => -1,
        AppThemeMode.dark => 0,
        AppThemeMode.light => 1,
      },
    );
    await _syncTray();
  }

  /// The taskbar switched between light and dark: swap the icon in place.
  Future<void> _syncTrayIcon() => tray.setIcon(
    trayIconAssetFor(taskbarLight: accessibility.taskbarLight.value),
  );

  Future<void> _syncTray() async {
    final settings = controller.settings;
    if (settings.keepRunningInBackground) {
      await tray.install(
        iconAsset: trayIconAssetFor(
          taskbarLight: accessibility.taskbarLight.value,
        ),
        tooltip: strings.appName,
        openLabel: strings.trayOpenSoftwareHub,
        endLabel: strings.trayEnd,
      );
    } else {
      await tray.remove();
    }
  }

  /// Shows and focuses the hub window, also out of the taskbar. The tray
  /// menu, notification clicks and a second launch of the Hub all lead here.
  Future<void> showHub() async {
    if (await windowManager.isMinimized()) await windowManager.restore();
    await windowManager.show();
    await windowManager.focus();
    await controller.startProcessWatch();
  }

  /// The tray menu's "End": leave the background surface (icon gone) and
  /// quit the process. When it is not running, nothing reacts to anything.
  Future<void> end() async {
    controller.stopProcessWatch();
    await tray.remove();
    await controller.installStagedOnExit();
    await windowManager.destroy();
  }

  /// A closed window sleeps in the tray when background running is set:
  /// the window is hidden whole, so the engine stops rendering while the
  /// hourly update watch keeps ticking underneath. Otherwise the process
  /// exits; [destroy] quits directly, past the close interception.
  @override
  void onWindowMinimize() => controller.stopProcessWatch();

  @override
  void onWindowRestore() {
    controller.startProcessWatch();
  }

  @override
  void onWindowClose() {
    if (controller.settings.keepRunningInBackground) {
      controller.stopProcessWatch();
      windowManager.hide();
    } else {
      controller.installStagedOnExit().whenComplete(windowManager.destroy);
    }
  }
}
