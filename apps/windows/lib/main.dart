import 'package:flutter/widgets.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_images/hub_images.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'platform/windows_accessibility.dart';
import 'background/background_service.dart';
import 'background/background_strings.dart';
import 'background/hub_notifications.dart';
import 'background/tray_surface.dart';
import 'background/update_watch_service.dart';
import 'presentation/controllers/hub_controller.dart';

/// Composition root of the Windows frontend.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final accessibility = WindowsAccessibility();
  await accessibility.initialize();

  final startDark = args.contains('--dark');
  final startLight = args.contains('--light');
  final openSettings = args.contains('--settings');

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1020, 780),
    minimumSize: Size(560, 580),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  final services = HubServices.production(args);
  final useCases = services.useCases;

  // The version the catalog compares against is the release version without
  // the pubspec build suffix (`0.1.11+1` -> `0.1.11`).
  final packageInfo = await PackageInfo.fromPlatform();
  final selfVersion = packageInfo.version.split('+').first;

  // The watcher's baseline follows what the window actually showed, so a
  // manual refresh never re-announces anything through the hourly watch.
  final watcher = CatalogUpdateWatcher(useCases);
  final controller = HubController(
    useCases,
    selfVersion: selfVersion,
    onCatalogSynced: () async {
      try {
        await watcher.rebaseline();
      } catch (error, stack) {
        reportBackgroundError(error, stack);
      }
    },
  );

  final strings = await BackgroundStrings.load(
    WidgetsBinding.instance.platformDispatcher.locale,
  );

  await controller.load(preferredId: null);
  if (startDark) {
    await controller.updateSettings(
      controller.settings.copyWith(themeMode: AppThemeMode.dark),
    );
  } else if (startLight) {
    await controller.updateSettings(
      controller.settings.copyWith(themeMode: AppThemeMode.light),
    );
  }

  // Out here the surface is not a widget: window, tray icon and OS
  // notifications outlive the window being visible.
  late final BackgroundService background;
  final tray = TraySurface(
    onOpenHub: () => background.showHub(),
    onEnd: () => background.end(),
  );
  final notifications = HubNotifications(
    onNotificationClicked: () => background.showHub(),
  );
  await notifications.setup(strings.appName);

  background = BackgroundService(
    controller: controller,
    tray: tray,
    strings: strings,
    watch: UpdateWatchService(
      watcher: watcher,
      settings: () => controller.settings,
      notify: ({required title, required body}) =>
          notifications.show(title: title, body: body),
      texts: strings,
    ),
  );
  // Now that `background` exists, the controller can leave the app after the
  // staged setup launched.
  controller.quitForUpdate = () => background.end();
  await background.start();

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    HubImageScope(
      icons: services.icons,
      child: DynamotivationApp(
        controller: controller,
        accessibility: accessibility,
        initialSettingsOpen: openSettings,
      ),
    ),
  );
}
