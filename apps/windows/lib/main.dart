import 'dart:async';
import 'dart:io';

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
import 'background/notification_icons.dart';
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
  // the pubspec build suffix (`0.1.12+1` -> `0.1.12`).
  final packageInfo = await PackageInfo.fromPlatform();
  final selfVersion = packageInfo.version.split('+').first;

  // What was announced lives in the cache folder, so a relaunch (including
  // the restart after a self-update) announces nothing twice. A manual
  // refresh counts what it showed as known; the startup load settles first
  // and then triggers the one startup summary (see below).
  final watcher = CatalogUpdateWatcher(useCases, store: services.announcements);
  final startupSettled = Completer<void>();
  final controller = HubController(
    useCases,
    selfVersion: selfVersion,
    onStartupSynced: () {
      if (!startupSettled.isCompleted) startupSettled.complete();
    },
    onCatalogSynced: () async {
      try {
        await watcher.markSeen();
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
  final notificationIcons = NotificationIcons(
    icons: services.icons,
    directory: Directory(
      '${cacheDirectory(hubCacheName).path}${Platform.pathSeparator}notification-icons',
    ),
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
      notify: ({required title, required body, iconUrl}) async =>
          notifications.show(
            title: title,
            body: body,
            imagePath: await notificationIcons.pngPath(iconUrl),
          ),
      showInApp: controller.postNotice,
      // Toasts are for a window that is unfocused or hidden in the tray.
      isWindowFocused: () async =>
          await windowManager.isVisible() && await windowManager.isFocused(),
      onRefreshed: controller.syncFromSource,
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

  // At most one summary of what the user was not told about before the last
  // close, once the catalog settled and the window is up (so a relaunched,
  // focused hub gets an in-app notice, never a toast).
  unawaited(
    startupSettled.future.then((_) => background.watch.announceStartup()),
  );

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
