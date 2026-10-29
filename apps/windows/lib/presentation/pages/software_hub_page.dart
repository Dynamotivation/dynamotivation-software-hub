import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:window_manager/window_manager.dart';

import '../controllers/hub_controller.dart';
import '../errors.dart';
import '../shortcuts.dart';
import '../theme/dynamotivation_theme.dart';
import '../widgets/package_detail_pane.dart';
import '../widgets/package_sidebar.dart';
import '../widgets/settings_view.dart';
import '../widgets/window_title_bar.dart';

class SoftwareHubPage extends StatefulWidget {
  final HubController controller;
  final bool initialSettingsOpen;

  const SoftwareHubPage({
    super.key,
    required this.controller,
    this.initialSettingsOpen = false,
  });

  @override
  State<SoftwareHubPage> createState() => _SoftwareHubPageState();
}

class _SoftwareHubPageState extends State<SoftwareHubPage> {
  String _searchQuery = '';
  final _searchFocus = FocusNode();
  late bool _isSettingsOpen;
  String? _lastWindowTitle;
  ({String title, String content, InfoBarSeverity severity})? _toast;
  Timer? _toastTimer;

  HubController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _isSettingsOpen = widget.initialSettingsOpen;
    final loadError = _controller.loadError;
    if (loadError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showError(loadError);
      });
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSettings() => setState(() => _isSettingsOpen = !_isSettingsOpen);

  /// Esc: leave settings, else clear an active search.
  void _escape() {
    if (_isSettingsOpen) {
      setState(() => _isSettingsOpen = false);
    } else if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = '');
    }
  }

  void _showInfo({
    required String title,
    required String content,
    InfoBarSeverity severity = InfoBarSeverity.success,
  }) {
    // One toast slot: a new message replaces the current one in place
    // instead of stacking, and fades/slides in and out (see build).
    _toastTimer?.cancel();
    setState(
      () => _toast = (title: title, content: content, severity: severity),
    );
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _showError(Object error) {
    final l10n = context.l10n;
    _showInfo(
      title: l10n.operationFailed,
      content: describeError(l10n, error),
      severity: InfoBarSeverity.error,
    );
  }

  Future<void> _handleRefresh() async {
    try {
      await _controller.refresh();
      if (!mounted) return;
      _showInfo(
        title: context.l10n.catalogSynchronized,
        content: context.l10n.catalogUpToDate,
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _handleUpdatePackage() async {
    try {
      final updated = await _controller.updateSelected();
      if (!mounted) return;
      _showInfo(
        title: context.l10n.packageUpdatedTitle(updated.name),
        content: context.l10n.packageUpdatedContent(updated.latestVersion),
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _handleInstallPackage() async {
    try {
      final installed = await _controller.installSelected();
      if (!mounted) return;
      _showInfo(
        title: context.l10n.packageInstalledTitle(installed.name),
        content: context.l10n.packageInstalledContent(installed.currentVersion),
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _handleUninstallPackage() async {
    final package = _controller.selected;
    if (package == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.uninstallConfirmTitle(package.name)),
        content: Text(l10n.uninstallConfirmBody),
        actions: [
          Button(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.uninstall),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final removed = await _controller.uninstallSelected();
      if (!mounted) return;
      _showInfo(
        title: l10n.packageUninstalledTitle(removed.name),
        content: l10n.packageUninstalledContent,
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  void _handleLaunchPackage() {
    final package = _controller.selected;
    if (package == null) return;
    _showInfo(
      title: context.l10n.launchingTitle(package.name),
      content: context.l10n.launchingContent(package.currentVersion),
      severity: InfoBarSeverity.info,
    );
  }

  /// Keeps the native window title (taskbar, alt-tab) on the localized
  /// product name. WinUI apps keep a constant window title while the
  /// in-app heading changes per view, so it only updates when needed.
  void _syncWindowTitle(String title) {
    if (_lastWindowTitle == title) return;
    _lastWindowTitle = title;
    windowManager.setTitle(title).catchError((error, stack) {
      // Window state sync, not user initiated: failures go to Flutter's
      // error handler, never to the UI.
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncWindowTitle(context.l10n.productName);

    return CallbackShortcuts(
      bindings: {
        AppShortcuts.settings: _toggleSettings,
        AppShortcuts.refresh: _handleRefresh,
        AppShortcuts.refreshAlt: _handleRefresh,
        AppShortcuts.search: () {
          if (_isSettingsOpen) setState(() => _isSettingsOpen = false);
          _searchFocus.requestFocus();
        },
        AppShortcuts.back: _escape,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => ColoredBox(
            color: DynTokens.of(context).window,
            child: Stack(
              children: [
                Column(
                  children: [
                    WindowTitleBar(
                      isSettingsOpen: _isSettingsOpen,
                      onToggleSettings: () =>
                          setState(() => _isSettingsOpen = !_isSettingsOpen),
                      hubUpdateVersion: '0.2.0',
                      onUpdateHub: () => _showInfo(
                        title: context.l10n.hubUpdateTitle,
                        content: context.l10n.hubUpdateReady('0.2.0'),
                        severity: InfoBarSeverity.info,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _isSettingsOpen
                            ? SettingsView(
                                settings: _controller.settings,
                                onSettingsChanged: _controller.updateSettings,
                                onBack: () =>
                                    setState(() => _isSettingsOpen = false),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PackageSidebar(
                                    packages: _controller.packages,
                                    departingIds: _controller.departingIds,
                                    selectedPackage: _controller.selected,
                                    onSelectPackage: _controller.select,
                                    searchQuery: _searchQuery,
                                    onSearchChanged: (q) =>
                                        setState(() => _searchQuery = q),
                                    onRefresh: _handleRefresh,
                                    isRefreshing: _controller.isRefreshing,
                                    searchFocusNode: _searchFocus,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: PackageDetailPane(
                                      package: _controller.selected,
                                      onUpdate: _handleUpdatePackage,
                                      onLaunch: _handleLaunchPackage,
                                      onInstall: _handleInstallPackage,
                                      onUninstall: _handleUninstallPackage,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedSwitcher(
                      duration: FluentTheme.of(context).mediumAnimationDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _toast == null
                          ? const SizedBox.shrink(key: ValueKey('none'))
                          : Semantics(
                              liveRegion: true,
                              key: ValueKey(_toast),
                              child: PhysicalModel(
                                color: Colors.transparent,
                                elevation: 8,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 520,
                                  ),
                                  // InfoBar is translucent; give it an
                                  // opaque base so nothing shows through.
                                  child: ColoredBox(
                                    color:
                                        FluentTheme.of(context).brightness ==
                                            Brightness.dark
                                        ? DynTokens.dark.card
                                        : DynTokens.light.card,
                                    child: InfoBar(
                                      title: Text(_toast!.title),
                                      content: Text(_toast!.content),
                                      severity: _toast!.severity,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
