import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

import 'models/package_catalog.dart';
import 'models/package_model.dart';
import 'models/settings_model.dart';
import 'theme/dynamotivation_theme.dart';
import 'widgets/package_detail_pane.dart';
import 'widgets/package_sidebar.dart';
import 'widgets/settings_view.dart';
import 'widgets/window_title_bar.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool startDark = args.contains('--dark');
  final bool openSettings = args.contains('--settings');

  if (Platform.isWindows) {
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
  }

  runApp(
    DynamotivationApp(
      initialDark: startDark,
      initialSettingsOpen: openSettings,
    ),
  );
}

class DynamotivationApp extends StatefulWidget {
  final bool initialDark;
  final bool initialSettingsOpen;

  const DynamotivationApp({
    super.key,
    this.initialDark = false,
    this.initialSettingsOpen = false,
  });

  @override
  State<DynamotivationApp> createState() => _DynamotivationAppState();
}

class _DynamotivationAppState extends State<DynamotivationApp> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings(
      themeMode: widget.initialDark ? AppThemeMode.dark : AppThemeMode.light,
    );
  }

  void _updateSettings(AppSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _updateMicaEffect();
  }

  void _updateMicaEffect() {
    if (!Platform.isWindows) return;
    final brightness = _resolvedBrightness();
    Window.setEffect(
      effect: WindowEffect.mica,
      color: Colors.transparent,
      dark: brightness == Brightness.dark,
    );
  }

  Brightness _resolvedBrightness() {
    switch (_settings.themeMode) {
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
    final brightness = _resolvedBrightness();
    final isDark = brightness == Brightness.dark;

    return FluentApp(
      title: 'Dynamotivation Software Hub',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: DynamotivationTheme.lightTheme(),
      darkTheme: DynamotivationTheme.darkTheme(),
      debugShowCheckedModeBanner: false,
      home: SoftwareHubHome(
        settings: _settings,
        onSettingsChanged: _updateSettings,
        initialSettingsOpen: widget.initialSettingsOpen,
      ),
    );
  }
}

class SoftwareHubHome extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final bool initialSettingsOpen;

  const SoftwareHubHome({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.initialSettingsOpen = false,
  });

  @override
  State<SoftwareHubHome> createState() => _SoftwareHubHomeState();
}

class _SoftwareHubHomeState extends State<SoftwareHubHome> {
  late List<SoftwarePackage> _packages;
  SoftwarePackage? _selectedPackage;
  String _searchQuery = '';
  late bool _isSettingsOpen;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _isSettingsOpen = widget.initialSettingsOpen;
    _packages = getInitialCatalog();
    _selectedPackage = _packages.firstWhere(
      (p) => p.id == 'geo-background-generator',
      orElse: () => _packages.first,
    );
  }

  void _handleSelectPackage(SoftwarePackage pkg) {
    setState(() {
      _selectedPackage = pkg;
    });
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Catalog Synchronized'),
          content: Text('All software package listings are up to date.'),
          severity: InfoBarSeverity.success,
        ),
      );
    }
  }

  void _handleUpdatePackage() {
    if (_selectedPackage == null) return;
    final current = _selectedPackage!;
    final updated = current.copyWith(
      currentVersion: current.latestVersion,
      status: PackageInstallationStatus.installed,
    );

    setState(() {
      final index = _packages.indexWhere((p) => p.id == current.id);
      if (index != -1) {
        _packages[index] = updated;
      }
      _selectedPackage = updated;
    });

    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text('${updated.name} Updated'),
        content: Text('Successfully updated to v${updated.latestVersion}.'),
        severity: InfoBarSeverity.success,
      ),
    );
  }

  void _handleLaunchPackage() {
    if (_selectedPackage == null) return;
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text('Launching ${_selectedPackage!.name}'),
        content: Text('Starting v${_selectedPackage!.currentVersion}...'),
        severity: InfoBarSeverity.info,
      ),
    );
  }

  void _handleRegisterPackage(String name) {
    final id = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final newPkg = SoftwarePackage(
      id: id,
      name: name,
      subtitle: 'Custom registered package',
      description: 'Custom registered package from your local catalog.',
      currentVersion: '1.0.0',
      latestVersion: '1.0.0',
      iconAsset: 'assets/dynamotivation-logo.svg',
      isSvgIcon: true,
      status: PackageInstallationStatus.installed,
      latestRelease: ReleaseNote(
        version: '1.0.0',
        date: DateTime.now().toString().split(' ')[0],
        highlights: const ['Initial package registration'],
      ),
      olderReleases: const [],
      availableVersions: const ['v1.0.0 (Latest)'],
    );

    setState(() {
      _packages.insert(0, newPkg);
      _selectedPackage = newPkg;
      _isSettingsOpen = false;
    });

    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Package Registered'),
        content: Text('"$name" has been added to your software library.'),
        severity: InfoBarSeverity.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Root stays transparent so the Mica backdrop shows between the opaque
    // header, cards and canvas (Windows 11 convention).
    return Column(
      children: [
        // Native-feel Title Bar with Dynamotivation identity
        WindowTitleBar(
          isSettingsOpen: _isSettingsOpen,
          onToggleSettings: () {
            setState(() {
              _isSettingsOpen = !_isSettingsOpen;
            });
          },
          hubUpdateVersion: '0.2.0',
        ),

        // Main App Content (Catalog or Settings)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isSettingsOpen
                ? SettingsView(
                    settings: widget.settings,
                    onSettingsChanged: widget.onSettingsChanged,
                    onBack: () {
                      setState(() {
                        _isSettingsOpen = false;
                      });
                    },
                    onRegisterPackage: _handleRegisterPackage,
                    onRefreshCatalog: _handleRefresh,
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Sidebar
                      PackageSidebar(
                        packages: _packages,
                        selectedPackage: _selectedPackage,
                        onSelectPackage: _handleSelectPackage,
                        searchQuery: _searchQuery,
                        onSearchChanged: _handleSearchChanged,
                        onRefresh: _handleRefresh,
                        isRefreshing: _isRefreshing,
                      ),

                      const SizedBox(width: 16),

                      // Right Detail Pane
                      Expanded(
                        child: PackageDetailPane(
                          package: _selectedPackage,
                          onUpdate: _handleUpdatePackage,
                          onLaunch: _handleLaunchPackage,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
