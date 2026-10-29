import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'presentation/controllers/hub_controller.dart';

/// Catalog published by the website. Override with `--catalog-url=<uri>`,
/// e.g. the local preview at http://127.0.0.1:1111/v1/catalog.json/.
final _defaultCatalogUri = Uri.parse(
  'https://dynamotivation.com/v1/catalog.json/',
);

Uri catalogUri(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--catalog-url=')) {
      return Uri.parse(arg.substring('--catalog-url='.length));
    }
  }
  return _defaultCatalogUri;
}

/// Composition root of the Windows frontend.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final controller = HubController(
    HubUseCases(
      WebsitePackageRepository(catalogUri(args)),
      InMemorySettingsRepository(),
    ),
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
    DynamotivationApp(
      controller: controller,
      initialSettingsOpen: openSettings,
    ),
  );
}
