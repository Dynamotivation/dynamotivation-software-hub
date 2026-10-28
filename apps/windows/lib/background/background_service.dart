import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../presentation/controllers/hub_controller.dart';
import 'background_strings.dart';
import 'tray_surface.dart';
import 'update_watch_service.dart';

/// The Windows system tray icon assets. The website publishes a light icon
/// for light tray backgrounds and a dark twin for dark ones.
const _trayIconLightAsset = 'assets/tray_icon.ico';
const _trayIconDarkAsset = 'assets/tray_icon_dark.ico';

/// The background half of the Windows frontend: what keeps running when the
/// hub window hides in the tray. Owns the close-button behavior, the tray
/// icon, and the hourly update watch; main.dart is the only wiring point.
///
/// Known limits: the tray icon variant is picked at installation time only,
/// and the update watch stops only with the process itself (the "End" tray
/// menu item), which is exactly the point of running in the background.
class BackgroundService with WindowListener {
  BackgroundService({
    required this.controller,
    required this.tray,
    required this.watch,
    required this.strings,
  });

  final HubController controller;
  final TraySurface tray;
  final UpdateWatchService watch;
  final BackgroundStrings strings;

  /// Registers everything the surface needs while the app runs. Safe to
  /// leave running for the whole session; "End" is the only stop.
  Future<void> start() async {
    controller.addListener(_syncFromSettings);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    watch.start();
    await _syncTray();
  }

  /// The tray icon exists exactly while background running is set.
  Future<void> _syncFromSettings() => _syncTray();

  Future<void> _syncTray() async {
    final settings = controller.settings;
    if (settings.keepRunningInBackground) {
      final isDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
      await tray.install(
        iconAsset: isDark ? _trayIconDarkAsset : _trayIconLightAsset,
        tooltip: strings.appName,
        openLabel: strings.trayOpenSoftwareHub,
        endLabel: strings.trayEnd,
      );
    } else {
      await tray.remove();
    }
  }

  /// Shows and focuses the hub window. The tray menu and notification
  /// clicks both lead here.
  Future<void> showHub() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// The tray menu's "End": leave the background surface (icon gone) and
  /// quit the process. When it is not running, nothing reacts to anything.
  Future<void> end() async {
    await tray.remove();
    await windowManager.destroy();
  }

  /// A closed window sleeps in the tray when background running is set:
  /// the window is hidden whole, so the engine stops rendering while the
  /// hourly update watch keeps ticking underneath. Otherwise the process
  /// exits; [destroy] quits directly, past the close interception.
  @override
  void onWindowClose() {
    if (controller.settings.keepRunningInBackground) {
      windowManager.hide();
    } else {
      windowManager.destroy();
    }
  }
}
