import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../controllers/hub_controller.dart';
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
  late bool _isSettingsOpen;

  HubController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _isSettingsOpen = widget.initialSettingsOpen;
  }

  void _showInfo({
    required String title,
    required String content,
    InfoBarSeverity severity = InfoBarSeverity.success,
  }) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(title),
        content: Text(content),
        severity: severity,
      ),
    );
  }

  void _showError(Object error) {
    final l10n = context.l10n;
    final detail = switch (error) {
      InvalidPackageName() => l10n.invalidPackageName,
      PackageAlreadyRegistered(:final id) => l10n.packageAlreadyRegistered(id),
      _ => error.toString(),
    };
    _showInfo(
      title: l10n.operationFailed,
      content: detail,
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

  void _handleLaunchPackage() {
    final package = _controller.selected;
    if (package == null) return;
    _showInfo(
      title: context.l10n.launchingTitle(package.name),
      content: context.l10n.launchingContent(package.currentVersion),
      severity: InfoBarSeverity.info,
    );
  }

  Future<void> _handleRegisterPackage(String name) async {
    final l10n = context.l10n;
    try {
      final created = await _controller.register(
        name: name,
        subtitle: l10n.customPackageSubtitle,
        description: l10n.customPackageDescription,
        initialHighlight: l10n.initialRegistration,
      );
      if (!mounted) return;
      setState(() => _isSettingsOpen = false);
      _showInfo(
        title: l10n.packageRegistered,
        content: l10n.packageAddedToLibrary(created.name),
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Root stays transparent so the Mica backdrop shows between the opaque
    // header, cards and canvas (Windows 11 convention).
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Column(
        children: [
          WindowTitleBar(
            isSettingsOpen: _isSettingsOpen,
            onToggleSettings: () =>
                setState(() => _isSettingsOpen = !_isSettingsOpen),
            hubUpdateVersion: '0.2.0',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isSettingsOpen
                  ? SettingsView(
                      settings: _controller.settings,
                      onSettingsChanged: _controller.updateSettings,
                      onBack: () => setState(() => _isSettingsOpen = false),
                      onRegisterPackage: _handleRegisterPackage,
                      onRefreshCatalog: _handleRefresh,
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
                          onRefresh: _handleRefresh,
                          isRefreshing: _controller.isRefreshing,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PackageDetailPane(
                            package: _controller.selected,
                            onUpdate: _handleUpdatePackage,
                            onLaunch: _handleLaunchPackage,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
