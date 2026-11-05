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
  final _searchFocus = FocusNode(debugLabel: 'Software search');
  final _settingsButtonFocus = FocusNode(debugLabel: 'Settings button');
  final _settingsBackFocus = FocusNode(debugLabel: 'Settings back');
  final _detailActionFocus = FocusNode(debugLabel: 'Package primary action');
  final _detailOverflowFocus = FocusNode(debugLabel: 'Package more options');
  FocusNode? _returnFocus;
  bool _compactDetail = false;
  late bool _isSettingsOpen;
  String? _lastWindowTitle;
  ({String title, String content, InfoBarSeverity severity})? _toast;
  Timer? _toastTimer;
  // Bump per message so the live-region node is rebuilt (and re-announced)
  // even when an identical status message follows the previous one.
  int _toastSequence = 0;

  HubController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _isSettingsOpen = widget.initialSettingsOpen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        (_isSettingsOpen ? _settingsBackFocus : _searchFocus).requestFocus();
      }
    });
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
    _settingsButtonFocus.dispose();
    _settingsBackFocus.dispose();
    _detailActionFocus.dispose();
    _detailOverflowFocus.dispose();
    super.dispose();
  }

  void _setSettings(bool open) {
    if (open == _isSettingsOpen) return;
    if (open) _returnFocus = FocusManager.instance.primaryFocus;
    setState(() => _isSettingsOpen = open);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (open) {
        _settingsBackFocus.requestFocus();
      } else {
        final target = _returnFocus;
        (target?.context != null && target!.canRequestFocus
                ? target
                : _settingsButtonFocus)
            .requestFocus();
      }
    });
  }

  void _toggleSettings() => _setSettings(!_isSettingsOpen);

  void _focusSearch() {
    _setSettings(false);
    setState(() => _compactDetail = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  /// Esc: leave settings, else clear an active search.
  void _escape() {
    if (_isSettingsOpen) {
      _setSettings(false);
    } else if (_compactDetail) {
      _focusSearch();
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
    _toastSequence++;
    setState(
      () => _toast = (title: title, content: content, severity: severity),
    );
    // Errors remain available until explicitly dismissed. Reduced-motion and
    // accessible-navigation users can also take as long as they need to read.
    if (severity != InfoBarSeverity.error &&
        !MediaQuery.accessibleNavigationOf(context)) {
      _toastTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _toast = null);
      });
    }
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
    if (package == null || package.deviceObserved) return;
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
    // Restore focus to the overflow menu trigger the dialog came from no
    // matter how the dialog was dismissed; opening it over the flyout route
    // loses focus otherwise.
    _detailOverflowFocus.requestFocus();
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

  Future<void> _handleLaunchPackage({bool anotherInstance = false}) async {
    final package = _controller.selected;
    if (package == null || !package.canLaunch) return;
    try {
      await _controller.launchSelected(anotherInstance: anotherInstance);
      if (!mounted) return;
      _showInfo(
        title: context.l10n.launchingTitle(package.name),
        content: context.l10n.launchingContent(package.currentVersion),
        severity: InfoBarSeverity.info,
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  VoidCallback? _forceCloseAction(String? id) =>
      id == null ? null : () => _handleForceClose(id);

  Future<void> _handleForceClose(String id) async {
    try {
      await _controller.forceClosePackage(id);
    } catch (error) {
      if (mounted) _showError(error);
    }
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
        AppShortcuts.search: _focusSearch,
        AppShortcuts.back: _escape,
      },
      child: Focus(
        canRequestFocus: false,
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
                      onToggleSettings: _toggleSettings,
                      settingsFocusNode: _settingsButtonFocus,
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
                                backFocusNode: _settingsBackFocus,
                                onBack: () => _setSettings(false),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 760;
                                  final sidebar = FocusTraversalGroup(
                                    child: PackageSidebar(
                                      packages: _controller.packages,
                                      departingIds: _controller.departingIds,
                                      selectedPackage: _controller.selected,
                                      onSelectPackage: (package) {
                                        _controller.select(package);
                                        if (compact) {
                                          setState(() => _compactDetail = true);
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (!mounted) return;
                                                _detailActionFocus
                                                    .requestFocus();
                                                final context =
                                                    _detailActionFocus.context;
                                                if (context != null) {
                                                  Scrollable.ensureVisible(
                                                    context,
                                                  );
                                                }
                                              });
                                        }
                                      },
                                      searchQuery: _searchQuery,
                                      onSearchChanged: (q) =>
                                          setState(() => _searchQuery = q),
                                      onRefresh: _handleRefresh,
                                      isRefreshing: _controller.isRefreshing,
                                      searchFocusNode: _searchFocus,
                                    ),
                                  );
                                  final detail = FocusTraversalGroup(
                                    child: PackageDetailPane(
                                      package: _controller.selected,
                                      onUpdate: _handleUpdatePackage,
                                      onLaunch: _handleLaunchPackage,
                                      onLaunchAnotherInstance: () =>
                                          _handleLaunchPackage(
                                            anotherInstance: true,
                                          ),
                                      onForceClose: _forceCloseAction(
                                        _controller.selected?.id,
                                      ),
                                      isRunning:
                                          _controller.selected != null &&
                                          _controller.isRunning(
                                            _controller.selected!.id,
                                          ),
                                      isLaunching:
                                          _controller.selected != null &&
                                          _controller.isLaunching(
                                            _controller.selected!.id,
                                          ),
                                      onInstall: _handleInstallPackage,
                                      onUninstall: _handleUninstallPackage,
                                      primaryActionFocus: _detailActionFocus,
                                      overflowFocus: _detailOverflowFocus,
                                      historyLoading: _controller
                                          .isLoadingHistory(
                                            _controller.selected?.id ?? '',
                                          ),
                                      historyError: _controller.historyError(
                                        _controller.selected?.id ?? '',
                                      ),
                                      onRetryHistory:
                                          _controller.loadSelectedHistory,
                                    ),
                                  );
                                  if (compact) {
                                    if (!_compactDetail) {
                                      return SizedBox.expand(child: sidebar);
                                    }
                                    return Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Button(
                                            onPressed: _focusSearch,
                                            child: Text(
                                              context.l10n.backToSoftware,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(child: detail),
                                      ],
                                    );
                                  }
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      sidebar,
                                      const SizedBox(width: 16),
                                      Expanded(child: detail),
                                    ],
                                  );
                                },
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
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : FluentTheme.of(context).mediumAnimationDuration,
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
                              key: ValueKey('toast-$_toastSequence'),
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
                                    color: DynTokens.of(context).card,
                                    child: InfoBar(
                                      isLong: true,
                                      onClose: () {
                                        _toastTimer?.cancel();
                                        setState(() => _toast = null);
                                      },
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
