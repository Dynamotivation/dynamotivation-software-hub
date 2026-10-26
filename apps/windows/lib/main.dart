import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hub_core/hub_core.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'presentation/controllers/hub_controller.dart';

/// Composition root of the Windows frontend.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final startDark = args.contains('--dark');
  final openSettings = args.contains('--settings');

  await Window.initialize();
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1020, 780),
    minimumSize: Size(560, 580),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  final controller = HubController(
    HubUseCases(InMemoryPackageRepository(), InMemorySettingsRepository()),
  );
  await controller.load(preferredId: 'geo-background-generator');
  if (startDark) {
    await controller.updateSettings(
      controller.settings.copyWith(themeMode: AppThemeMode.dark),
    );
  }

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Apply Mica after the hidden title bar is set, otherwise the backdrop
    // is not drawn.
    await Window.setEffect(
      effect: WindowEffect.mica,
      color: Colors.transparent,
      dark: startDark,
    );
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    DynamotivationApp(
      controller: controller,
      initialSettingsOpen: openSettings,
      syncMica: true,
    ),
  );
}
