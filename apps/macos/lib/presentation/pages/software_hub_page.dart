import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';

import '../controllers/hub_controller.dart';
import '../errors.dart';
import '../theme/dynamotivation_macos_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/glass_controls.dart';
import '../widgets/mac_window_controls_preview.dart';
import '../widgets/package_detail_view.dart';
import '../widgets/package_icon.dart';
import '../widgets/package_list.dart';
import '../widgets/settings_view.dart';

/// Height of the floating toolbar row, including its margin.
const _toolbarInset = 56.0;

class SoftwareHubPage extends StatefulWidget {
  final HubController controller;

  /// Draws fake traffic lights (design preview outside macOS).
  final bool macChromePreview;

  const SoftwareHubPage({
    super.key,
    required this.controller,
    this.macChromePreview = false,
  });

  @override
  State<SoftwareHubPage> createState() => _SoftwareHubPageState();
}

class _SoftwareHubPageState extends State<SoftwareHubPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _sidebarScroll = ScrollController();
  final _contentScroll = ScrollController();
  String? _status;
  Timer? _statusTimer;
  bool _showSettings = false;

  HubController get _controller => widget.controller;

  bool get _isMac => defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void dispose() {
    _statusTimer?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _sidebarScroll.dispose();
    _contentScroll.dispose();
    super.dispose();
  }

  /// Transient confirmation shown at the bottom of the content area.
  void _flash(String message) {
    _statusTimer?.cancel();
    setState(() => _status = message);
    _statusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _status = null);
    });
  }

  void _showError(Object error) {
    final l10n = context.l10n;
    showMacosAlertDialog<void>(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.exclamationmark_triangle),
        title: Text(l10n.operationFailed),
        message: Text(describeError(l10n, error)),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    try {
      await _controller.refresh();
      if (mounted) _flash(context.l10n.catalogUpToDate);
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _update() async {
    try {
      final updated = await _controller.updateSelected();
      if (!mounted) return;
      _flash(
        '${context.l10n.packageUpdatedTitle(updated.name)}. '
        '${context.l10n.packageUpdatedContent(updated.latestVersion)}',
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _install() async {
    try {
      final installed = await _controller.installSelected();
      if (!mounted) return;
      _flash(
        '${context.l10n.packageInstalledTitle(installed.name)}. '
        '${context.l10n.packageInstalledContent(installed.currentVersion)}',
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _uninstall() async {
    final package = _controller.selected;
    if (package == null) return;
    final l10n = context.l10n;
    final confirmed = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: PackageIcon(package: package, size: 56),
        title: Text(l10n.uninstallConfirmTitle(package.name)),
        message: Text(l10n.uninstallConfirmBody),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.uninstall),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final removed = await _controller.uninstallSelected();
      if (!mounted) return;
      _flash(
        '${l10n.packageUninstalledTitle(removed.name)}. '
        '${l10n.packageUninstalledContent}',
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  void _launch() {
    final package = _controller.selected;
    if (package == null) return;
    final l10n = context.l10n;
    _flash(
      '${l10n.launchingTitle(package.name)}. '
      '${l10n.launchingContent(package.currentVersion)}',
    );
  }

  void _toggleSettings() => setState(() => _showSettings = !_showSettings);

  static const _ctrlR = SingleActivator(LogicalKeyboardKey.keyR, control: true);
  static const _cmdR = SingleActivator(LogicalKeyboardKey.keyR, meta: true);
  static const _ctrlComma = SingleActivator(
    LogicalKeyboardKey.comma,
    control: true,
  );
  static const _cmdComma = SingleActivator(
    LogicalKeyboardKey.comma,
    meta: true,
  );

  /// Esc: leave settings, else clear an active search.
  void _escape() {
    if (_showSettings) {
      _toggleSettings();
    } else if (_search.text.isNotEmpty) {
      _search.clear();
    }
  }

  void _focusSearch() => _searchFocus.requestFocus();

  /// Toolbar while Settings is open: just a way back.
  Widget _settingsBar(AppLocalizations l10n, bool chrome) {
    return Row(
      children: [
        // Room for the traffic lights, which sit over this area now.
        SizedBox(width: chrome ? 76 : 0),
        GlassGroup(
          onGradient: false,
          children: [
            GlassIconButton(
              icon: CupertinoIcons.chevron_left,
              label: l10n.backToSoftware,
              onGradient: false,
              onPressed: _toggleSettings,
            ),
          ],
        ),
        Expanded(child: _dragArea(const SizedBox(height: 40))),
      ],
    );
  }

  static const _transition = Duration(milliseconds: 280);

  /// Cross-fades between the main and settings states.
  Widget _fade(Widget child) => AnimatedSwitcher(
    duration: _transition,
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    child: child,
  );

  /// Drag-to-move for the hidden title bar; only meaningful on macOS.
  Widget _dragArea(Widget child) => (_isMac || widget.macChromePreview)
      ? DragToMoveArea(child: child)
      : child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chrome = _isMac || widget.macChromePreview;

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _search]),
      builder: (context, _) {
        final theme = MacosTheme.of(context);
        final isDark = theme.brightness.isDark;
        final query = _search.text.trim().toLowerCase();
        final packages = _controller.packages
            .where((p) => p.name.toLowerCase().contains(query))
            .toList();
        final selected = _controller.selected;
        final canvas = isDark ? DynBrand.canvasDark : DynBrand.canvasLight;
        final sidebarColor = isDark
            ? DynBrand.sidebarDark
            : DynBrand.sidebarLight;
        final onGradient = !_showSettings && selected != null;

        // Floating sidebar panel (navigation layer).
        final sidebar = Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: sidebarColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _dragArea(
                  Column(
                    children: [
                      SizedBox(height: chrome ? 38 : 14),
                      const BrandLockup(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: MacosSearchField(
                    controller: _search,
                    focusNode: _searchFocus,
                    placeholder: l10n.searchSoftware,
                    // Default placeholder is ~2:1; use 60% label (>= 5:1).
                    placeholderStyle: TextStyle(
                      color:
                          (isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF000000))
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  child: PackageList(
                    packages: packages,
                    selected: selected,
                    controller: _sidebarScroll,
                    onSelect: (p) {
                      setState(() => _showSettings = false);
                      _controller.select(p);
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        // Floating toolbar: actions and search, on glass.
        final toolbar = Positioned(
          top: 10,
          right: 14,
          left: 14,
          // Only the empty part of the toolbar drags the window; the buttons
          // must stay outside the drag area or it swallows their clicks.
          child: _fade(
            _showSettings
                ? KeyedSubtree(
                    key: const ValueKey('settings-bar'),
                    child: _settingsBar(l10n, chrome),
                  )
                : KeyedSubtree(
                    key: const ValueKey('main-bar'),
                    child: Row(
                      children: [
                        Expanded(child: _dragArea(const SizedBox(height: 40))),
                        GlassGroup(
                          onGradient: onGradient,
                          children: [
                            if (_controller.isRefreshing)
                              const SizedBox(
                                width: 34,
                                height: 30,
                                child: Center(child: ProgressCircle(radius: 7)),
                              )
                            else
                              GlassIconButton(
                                icon: CupertinoIcons.arrow_clockwise,
                                label: l10n.checkForUpdates,
                                onGradient: onGradient,
                                shortcut: _isMac ? _cmdR : _ctrlR,
                                onPressed: _refresh,
                              ),
                            GlassIconButton(
                              icon: CupertinoIcons.gear,
                              label: l10n.settings,
                              onGradient: onGradient,
                              shortcut: _isMac ? _cmdComma : _ctrlComma,
                              onPressed: _toggleSettings,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        );

        final content = Stack(
          children: [
            Positioned.fill(
              child: _fade(
                _showSettings
                    ? SettingsView(
                        key: const ValueKey('settings'),
                        settings: _controller.settings,
                        onSettingsChanged: _controller.updateSettings,
                        topInset: _toolbarInset + 8,
                      )
                    : PackageDetailView(
                        key: const ValueKey('detail'),
                        package: selected,
                        scrollController: _contentScroll,
                        onUpdate: _update,
                        onInstall: _install,
                        onUninstall: _uninstall,
                        onLaunch: _launch,
                        topInset: _toolbarInset,
                      ),
              ),
            ),
            toolbar,
            Positioned(
              left: 24,
              right: 24,
              bottom: 20,
              // One slot: a new message replaces the old one in place and
              // both fade/slide, instead of cutting in and out.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
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
                child: _status == null
                    ? const SizedBox.shrink(key: ValueKey('none'))
                    : _StatusPill(key: ValueKey(_status), message: _status!),
              ),
            ),
          ],
        );

        Widget body = ColoredBox(
          color: canvas,
          child: Stack(
            children: [
              Row(
                children: [
                  // Settings are global, not per package: use the full window.
                  // Slides away for Settings, which use the full window.
                  AnimatedContainer(
                    duration: _transition,
                    curve: Curves.easeInOutCubic,
                    width: _showSettings ? 0 : 276,
                    child: ClipRect(
                      child: ExcludeFocus(
                        excluding: _showSettings,
                        child: ExcludeSemantics(
                          excluding: _showSettings,
                          child: OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: 276,
                            maxWidth: 276,
                            child: sidebar,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
              if (widget.macChromePreview)
                const Positioned(
                  top: 22,
                  left: 28,
                  child: MacWindowControlsPreview(),
                ),
            ],
          ),
        );

        // Keyboard shortcuts. On macOS the menu bar owns Cmd+, / R / F.
        {
          body = CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _escape,
              const SingleActivator(LogicalKeyboardKey.f5): _refresh,
              if (!_isMac) ...{
                const SingleActivator(LogicalKeyboardKey.comma, control: true):
                    _toggleSettings,
                const SingleActivator(LogicalKeyboardKey.comma, meta: true):
                    _toggleSettings,
                const SingleActivator(LogicalKeyboardKey.keyR, control: true):
                    _refresh,
                const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
                    _refresh,
                const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                    _focusSearch,
                const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                    _focusSearch,
              },
            },
            child: Focus(autofocus: true, child: body),
          );
        }

        return PlatformMenuBar(
          menus: [
            PlatformMenu(
              label: l10n.appTitle,
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: '${l10n.settings}…',
                      shortcut: const SingleActivator(
                        LogicalKeyboardKey.comma,
                        meta: true,
                      ),
                      onSelected: _toggleSettings,
                    ),
                  ],
                ),
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.quit,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.quit,
                  ),
              ],
            ),
            PlatformMenu(
              label: l10n.menuView,
              menus: [
                PlatformMenuItem(
                  label: l10n.checkForUpdates,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyR,
                    meta: true,
                  ),
                  onSelected: _refresh,
                ),
                PlatformMenuItem(
                  label: l10n.searchSoftware.replaceAll('...', ''),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyF,
                    meta: true,
                  ),
                  onSelected: _focusSearch,
                ),
              ],
            ),
          ],
          child: body,
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String message;

  const _StatusPill({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: theme.dividerColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Semantics(
            liveRegion: true,
            child: Text(message, style: theme.typography.callout),
          ),
        ),
      ),
    );
  }
}
