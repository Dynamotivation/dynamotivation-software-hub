import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:macos_ui/macos_ui.dart';

import 'presentation/controllers/hub_controller.dart';
import 'presentation/pages/software_hub_page.dart';
import 'presentation/theme/dynamotivation_macos_theme.dart';

class DynamotivationMacosApp extends StatelessWidget {
  final HubController controller;
  final bool macChromePreview;

  const DynamotivationMacosApp({
    super.key,
    required this.controller,
    this.macChromePreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MacosApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: DynBrand.light(),
        darkTheme: DynBrand.dark(),
        themeMode: switch (controller.settings.themeMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.system => ThemeMode.system,
        },
        debugShowCheckedModeBanner: false,
        home: SoftwareHubPage(
          controller: controller,
          macChromePreview: macChromePreview,
        ),
      ),
    );
  }
}
