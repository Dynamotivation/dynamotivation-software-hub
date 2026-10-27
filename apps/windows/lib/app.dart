import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';

import 'presentation/controllers/hub_controller.dart';
import 'presentation/pages/software_hub_page.dart';
import 'presentation/theme/dynamotivation_theme.dart';

class DynamotivationApp extends StatefulWidget {
  final HubController controller;
  final bool initialSettingsOpen;

  const DynamotivationApp({
    super.key,
    required this.controller,
    this.initialSettingsOpen = false,
  });

  @override
  State<DynamotivationApp> createState() => _DynamotivationAppState();
}

class _DynamotivationAppState extends State<DynamotivationApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// OS switched between light and dark while in System mode.
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Brightness _resolvedBrightness() {
    switch (widget.controller.settings.themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isDark = _resolvedBrightness() == Brightness.dark;
        return FluentApp(
          onGenerateTitle: (context) => context.l10n.appTitle,
          // Window chrome accent/frame color: the brand color, following the
          // FluentApp.color pattern from the fluent_ui gallery.
          color: DynamotivationTheme.coralPrimary,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: DynamotivationTheme.lightTheme(),
          darkTheme: DynamotivationTheme.darkTheme(),
          debugShowCheckedModeBanner: false,
          home: SoftwareHubPage(
            controller: widget.controller,
            initialSettingsOpen: widget.initialSettingsOpen,
          ),
        );
      },
    );
  }
}
