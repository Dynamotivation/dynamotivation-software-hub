import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';

import 'platform/windows_accessibility.dart';

import 'presentation/controllers/hub_controller.dart';
import 'presentation/pages/software_hub_page.dart';
import 'presentation/theme/dynamotivation_theme.dart';

class DynamotivationApp extends StatefulWidget {
  final HubController controller;
  final bool initialSettingsOpen;
  final WindowsAccessibility? accessibility;

  const DynamotivationApp({
    super.key,
    required this.controller,
    this.initialSettingsOpen = false,
    this.accessibility,
  });

  @override
  State<DynamotivationApp> createState() => _DynamotivationAppState();
}

class _DynamotivationAppState extends State<DynamotivationApp>
    with WidgetsBindingObserver {
  // Built once. A fresh FluentThemeData per rebuild makes FluentApp animate
  // between two equal themes, and the half-lerped button shapes flash square.
  final _lightTheme = DynamotivationTheme.lightTheme();
  final _darkTheme = DynamotivationTheme.darkTheme();

  late final _reducedLight = _withoutMotion(_lightTheme);
  late final _reducedDark = _withoutMotion(_darkTheme);
  FluentThemeData _withoutMotion(FluentThemeData theme) => theme.copyWith(
    fasterAnimationDuration: Duration.zero,
    fastAnimationDuration: Duration.zero,
    mediumAnimationDuration: Duration.zero,
    slowAnimationDuration: Duration.zero,
  );

  WindowsContrastPalette? _lastPalette;
  FluentThemeData? _contrastTheme;

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

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
      listenable: Listenable.merge([widget.controller, ?widget.accessibility]),
      builder: (context, _) {
        final palette = widget.accessibility?.value;
        if (palette != _lastPalette) {
          _lastPalette = palette;
          _contrastTheme = palette != null && palette.enabled
              ? DynamotivationTheme.systemContrastTheme(palette)
              : null;
        }
        final isDark =
            (_contrastTheme?.brightness ?? _resolvedBrightness()) ==
            Brightness.dark;
        final reducedMotion = WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
        return WindowsContrastScope(
          palette: palette,
          child: FluentApp(
            onGenerateTitle: (context) => context.l10n.appTitle,
            // Window chrome accent/frame color: the brand color, following the
            // FluentApp.color pattern from the fluent_ui gallery.
            color: palette?.enabled == true
                ? palette!.window
                : DynamotivationTheme.coralPrimary,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme:
                _contrastTheme ?? (reducedMotion ? _reducedLight : _lightTheme),
            darkTheme:
                _contrastTheme ?? (reducedMotion ? _reducedDark : _darkTheme),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(highContrast: palette?.enabled),
              child: reducedMotion || palette?.enabled == true
                  ? FluentTheme(
                      data:
                          _contrastTheme ??
                          (isDark ? _reducedDark : _reducedLight),
                      child: child!,
                    )
                  : child!,
            ),
            debugShowCheckedModeBanner: false,
            home: SoftwareHubPage(
              controller: widget.controller,
              initialSettingsOpen: widget.initialSettingsOpen,
            ),
          ),
        );
      },
    );
  }
}
