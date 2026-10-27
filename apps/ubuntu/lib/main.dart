import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';
import 'package:yaru_window_manager/yaru_window_manager.dart';

import 'app.dart';
import 'presentation/controllers/hub_controller.dart';

/// Composition root of the Ubuntu frontend.
/// Runs natively on Linux/Ubuntu, and on Windows as a design preview.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Route `YaruWindow` (used by YaruWindowTitleBar, drag & window controls)
  // through window_manager on platforms without a native yaru_window plugin.
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
    YaruWindowManager.registerWith();
  }

  final startDark = args.contains('--dark');
  final startLight = args.contains('--light');
  final openSettings = args.contains('--settings');

  await windowManager.ensureInitialized();
  // Hides the native title bar and prepares the in-scene Yaru window title bar.
  await YaruWindowTitleBar.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1060, 780),
    minimumSize: Size(640, 560),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  // Construct repository adapters and use cases
  final controller = HubController(
    HubUseCases(InMemoryPackageRepository(), InMemorySettingsRepository()),
  );
  await controller.load(preferredId: 'geo-background-generator');

  if (startDark) {
    await controller.updateSettings(
      controller.settings.copyWith(themeMode: AppThemeMode.dark),
    );
  } else if (startLight) {
    await controller.updateSettings(
      controller.settings.copyWith(themeMode: AppThemeMode.light),
    );
  }

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    DynamotivationUbuntuApp(
      controller: controller,
      initialSettingsOpen: openSettings,
    ),
  );
}
