import 'package:flutter/material.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:yaru/yaru.dart';

import 'presentation/controllers/hub_controller.dart';
import 'presentation/pages/software_hub_page.dart';
import 'presentation/theme/dynamotivation_ubuntu_theme.dart';

class DynamotivationUbuntuApp extends StatelessWidget {
  final HubController controller;
  final bool initialSettingsOpen;

  const DynamotivationUbuntuApp({
    super.key,
    required this.controller,
    this.initialSettingsOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => YaruTheme(
        builder: (context, yaru, child) {
          final mode = switch (controller.settings.themeMode) {
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.system => ThemeMode.system,
          };

          return MaterialApp(
            onGenerateTitle: (context) => context.l10n.appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Brand tokens are fused on top of the runtime-resolved Yaru
            // themes (same pattern as the Ubuntu App Center). The base themes
            // follow the user's GTK theme name, GNOME color scheme and
            // accent on non-brand surfaces, and carry the system font.
            theme: DynUbuntuTheme.light(yaru.theme),
            darkTheme: DynUbuntuTheme.dark(yaru.darkTheme),
            highContrastTheme: DynUbuntuTheme.highContrastLight(
              yaruHighContrastLight,
            ),
            highContrastDarkTheme: DynUbuntuTheme.highContrastDark(
              yaruHighContrastDark,
            ),
            themeMode: mode,
            debugShowCheckedModeBanner: false,
            home: SoftwareHubPage(
              controller: controller,
              initialSettingsOpen: initialSettingsOpen,
            ),
          );
        },
      ),
    );
  }
}
