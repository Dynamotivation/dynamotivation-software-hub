import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../controllers/hub_controller.dart';
import '../errors.dart';
import '../shortcuts.dart';
import '../theme/dynamotivation_ubuntu_theme.dart';
import '../widgets/package_detail_view.dart';
import '../widgets/package_sidebar.dart';
import '../widgets/settings_view.dart';
import '../widgets/ubuntu_header_bar.dart';

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
  final _searchFocusNode = FocusNode();
  final _detailScrollController = ScrollController();
  late bool _isSettingsOpen;
  String _searchQuery = '';
  _ToastState? _toast;
  Timer? _toastTimer;

  HubController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _isSettingsOpen = widget.initialSettingsOpen;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _searchFocusNode.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toast = _ToastState(message: message, isError: isError);
    });
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _showError(Object error) {
    final l10n = context.l10n;
    _showNotification(describeError(l10n, error), isError: true);
  }

  Future<void> _handleRefresh() async {
    try {
      await _controller.refresh();
      if (!mounted) return;
      _showNotification(context.l10n.catalogUpToDate);
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _handleUpdatePackage() async {
    try {
      final updated = await _controller.updateSelected();
      if (!mounted) return;
      _showNotification(
        '${context.l10n.packageUpdatedTitle(updated.name)}. ${context.l10n.packageUpdatedContent(updated.latestVersion)}',
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _handleInstallPackage() async {
    try {
      final installed = await _controller.installSelected();
      if (!mounted) return;
      _showNotification(
        '${context.l10n.packageInstalledTitle(installed.name)}. ${context.l10n.packageInstalledContent(installed.currentVersion)}',
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _handleUninstallPackage() async {
    try {
      final uninstalled = await _controller.uninstallSelected();
      if (!mounted) return;
      final l10n = context.l10n;
      _showNotification(
        '${l10n.packageUninstalledTitle(uninstalled.name)}. ${l10n.packageUninstalledContent}',
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _handleLaunchPackage() async {
    final pkg = _controller.selected;
    if (pkg == null) return;
    final l10n = context.l10n;
    _showNotification(
      '${l10n.launchingTitle(pkg.name)}: ${l10n.launchingContent(pkg.currentVersion)}',
    );
  }

  void _toggleSettings() {
    setState(() => _isSettingsOpen = !_isSettingsOpen);
  }

  void _focusSearch() {
    if (_isSettingsOpen) {
      setState(() => _isSettingsOpen = false);
    }
    _searchFocusNode.requestFocus();
  }

  void _escape() {
    if (_isSettingsOpen) {
      setState(() => _isSettingsOpen = false);
    } else if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => CallbackShortcuts(
        bindings: {
          AppShortcuts.settings: _toggleSettings,
          AppShortcuts.refresh: _handleRefresh,
          AppShortcuts.refreshAlt: _handleRefresh,
          AppShortcuts.search: _focusSearch,
          AppShortcuts.back: _escape,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  children: [
                    UbuntuHeaderBar(
                      isSettingsOpen: _isSettingsOpen,
                      onToggleSettings: _toggleSettings,
                      onRefresh: _handleRefresh,
                      isRefreshing: _controller.isRefreshing,
                      onFocusSearch: _focusSearch,
                    ),
                    Expanded(
                      child: _isSettingsOpen
                          ? SettingsView(
                              settings: _controller.settings,
                              onSettingsChanged: (s) =>
                                  _controller.updateSettings(s),
                              onClose: () =>
                                  setState(() => _isSettingsOpen = false),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PackageSidebar(
                                  packages: _controller.packages,
                                  selectedPackage: _controller.selected,
                                  onSelectPackage: _controller.select,
                                  searchQuery: _searchQuery,
                                  onSearchChanged: (q) =>
                                      setState(() => _searchQuery = q),
                                  searchFocusNode: _searchFocusNode,
                                ),
                                Expanded(
                                  child: PackageDetailView(
                                    package: _controller.selected,
                                    scrollController: _detailScrollController,
                                    onUpdate: _handleUpdatePackage,
                                    onLaunch: _handleLaunchPackage,
                                    onInstall: _handleInstallPackage,
                                    onUninstall: _handleUninstallPackage,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),

                // Ubuntu GNOME style notification banner
                if (_toast != null)
                  Positioned(
                    top: 56,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _UbuntuNotificationBanner(
                        message: _toast!.message,
                        isError: _toast!.isError,
                        onDismiss: () => setState(() => _toast = null),
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

class _ToastState {
  final String message;
  final bool isError;

  const _ToastState({required this.message, this.isError = false});
}

class _UbuntuNotificationBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _UbuntuNotificationBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isError
              ? DynUbuntuTheme.crimson
              : DynUbuntuTheme.ubuntuAubergineDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 14, color: Colors.white70),
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
