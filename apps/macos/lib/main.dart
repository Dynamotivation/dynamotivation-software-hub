import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'presentation/controllers/hub_controller.dart';

/// Composition root of the macOS frontend. It also runs on Windows as a
/// design preview; native window effects are only configured on macOS.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Off macOS the app is a design preview wearing macOS chrome: no native
  // title bar, painted (but working) traffic lights.
  final preview = !args.contains('--no-mac-chrome') && !Platform.isMacOS;

  if (Platform.isMacOS || preview) {
    // Full-size content under a transparent title bar; the system keeps
    // drawing the traffic lights, the toolbar row is the drag area.
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1100, 780),
        minimumSize: Size(720, 520),
        center: true,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  final controller = HubController(
    HubUseCases(InMemoryPackageRepository(), InMemorySettingsRepository()),
  );
  await controller.load(preferredId: 'geo-background-generator');
  final forced = args.contains('--dark')
      ? AppThemeMode.dark
      : args.contains('--light')
      ? AppThemeMode.light
      : null;
  if (forced != null) {
    await controller.updateSettings(
      controller.settings.copyWith(themeMode: forced),
    );
  }

  runApp(
    DynamotivationMacosApp(controller: controller, macChromePreview: preview),
  );
}
