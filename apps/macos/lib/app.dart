import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';

import 'presentation/controllers/hub_controller.dart';
import 'presentation/pages/software_hub_page.dart';
import 'presentation/theme/dynamotivation_macos_theme.dart';

class DynamotivationMacosApp extends StatefulWidget {
  final HubController controller;
  final bool macChromePreview;

  const DynamotivationMacosApp({
    super.key,
    required this.controller,
    this.macChromePreview = false,
  });

  @override
  State<DynamotivationMacosApp> createState() => _DynamotivationMacosAppState();
}

class _DynamotivationMacosAppState extends State<DynamotivationMacosApp>
    with WindowListener {
  /// Whether this window is frontmost. macOS dims controls in inactive
  /// windows (macos_ui themes read `isMainWindow`); starting as active is
  /// correct whenever no window-manager events have been delivered yet
  /// (e.g. in tests).
  bool _isMainWindow = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    if (mounted) setState(() => _isMainWindow = true);
  }

  @override
  void onWindowBlur() {
    if (mounted) setState(() => _isMainWindow = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => MacosApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: DynBrand.light(isMainWindow: _isMainWindow),
        darkTheme: DynBrand.dark(isMainWindow: _isMainWindow),
        themeMode: switch (widget.controller.settings.themeMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.system => ThemeMode.system,
        },
        debugShowCheckedModeBanner: false,
        home: SoftwareHubPage(
          controller: widget.controller,
          macChromePreview: widget.macChromePreview,
        ),
      ),
    );
  }
}
