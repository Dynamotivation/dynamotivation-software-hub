import '../user_date_format.dart';

import 'package:fluent_ui/fluent_ui.dart';

import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_scroll/hub_scroll.dart';

import '../theme/dynamotivation_theme.dart';
import 'package_image.dart';
import 'overflow_menu.dart';
import 'version_label.dart';
import 'run_action_button.dart';
import 'setup_action_button.dart';
import 'animated_action_width.dart';

class PackageDetailPane extends StatefulWidget {
  final SoftwarePackage? package;
  final VoidCallback onUpdate;
  final VoidCallback onLaunch;
  final VoidCallback? onLaunchAnotherInstance;
  final VoidCallback? onForceClose;
  final bool isRunning;
  final bool isLaunching;

  /// True while any setup runs: every action is disabled.
  final bool busy;

  /// True while this package's setup runs; [setupDownloadFraction] is its
  /// download progress, null once the setup itself runs.
  final bool setupInProgress;
  final double? setupDownloadFraction;

  /// Status of an uninstall or version switch of this installed package; it
  /// shows, with [setupDownloadFraction], in Launch's place. Null otherwise.
  final String? launchSlotStatus;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  /// Opens the choice of a specific version; null hides it.
  final VoidCallback? onInstallVersion;
  final FocusNode? primaryActionFocus;
  final FocusNode? overflowFocus;

  /// The older releases are fetched when the details view opens.
  final bool historyLoading;
  final Object? historyError;
  final VoidCallback onRetryHistory;

  const PackageDetailPane({
    super.key,
    required this.package,
    required this.onUpdate,
    required this.onLaunch,
    this.onLaunchAnotherInstance,
    this.onForceClose,
    this.isRunning = false,
    this.isLaunching = false,
    this.busy = false,
    this.setupInProgress = false,
    this.setupDownloadFraction,
    this.launchSlotStatus,
    required this.onInstall,
    required this.onUninstall,
    this.onInstallVersion,
    this.primaryActionFocus,
    this.overflowFocus,
    this.historyLoading = false,
    this.historyError,
    required this.onRetryHistory,
  });

  @override
  State<PackageDetailPane> createState() => _PackageDetailPaneState();
}

class _PackageDetailPaneState extends State<PackageDetailPane> {
  bool _olderExpanded = false;
  String? _selectedVersion;
  final _scroll = SmoothScrollController();

  /// Whether the package has a release besides the installed one to choose.
  bool _hasOtherVersions(SoftwarePackage pkg) =>
      widget.onInstallVersion != null &&
      (pkg.olderReleaseCount > 0 || !pkg.isInstalled);

  /// Launch, or the progress of an uninstall or version switch in its place
  /// while that runs.
  Widget _launchOrUninstalling(SoftwarePackage pkg, {required bool primary}) {
    final status = widget.launchSlotStatus;
    if (status != null) {
      return SetupActionButton(
        icon: FluentIcons.history,
        label: pkg.name,
        runningStatus: status,
        inProgress: true,
        downloadFraction: widget.setupDownloadFraction,
        enabled: false,
        filled: false,
        focusNode: widget.primaryActionFocus,
      );
    }
    return RunActionButton(
      name: pkg.name,
      running: widget.isRunning,
      busy: widget.isLaunching,
      enabled: pkg.canLaunch && !widget.busy,
      primary: primary,
      focusNode: widget.primaryActionFocus,
      onLaunch: (another) => another
          ? (widget.onLaunchAnotherInstance ?? widget.onLaunch)()
          : widget.onLaunch(),
      onForceClose: widget.onForceClose ?? () {},
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PackageDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.package?.id != widget.package?.id) {
      _olderExpanded = false;
      _selectedVersion = widget.package?.availableVersions.firstOrNull;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = DynTokens.of(context);

    if (widget.package == null) {
      return Center(
        child: Text(
          context.l10n.selectPackagePrompt,
          style: TextStyle(fontSize: 14, color: tokens.textMuted),
        ),
      );
    }

    final pkg = widget.package!;
    _selectedVersion ??= pkg.availableVersions.firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SmoothScroll(
          controller: _scroll,
          child: ListView(
            controller: _scroll,
            physics: smoothScrollPhysics,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: [
              Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Top Header: Icon + Title + Status + Action Buttons
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large package icon
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tokens.cardBorder,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.08,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: packageImage(pkg, BoxFit.cover),
                        ),

                        const SizedBox(width: 18),

                        // Name & Version & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  pkg.name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.text,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Plain status line: icon + label, then version(s).
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (pkg.hasUpdate) ...[
                                    Text(
                                      versionLabel(pkg.currentVersion),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: tokens.textMuted,
                                      ),
                                    ),
                                    Text(
                                      context.l10n.updateAvailable,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: DynTokens.of(context).brandRed,
                                      ),
                                    ),
                                  ] else ...[
                                    if (pkg.isInstalled)
                                      Icon(
                                        FluentIcons.check_mark,
                                        size: 12,
                                        color: tokens.success,
                                      ),
                                    Text(
                                      versionLabel(
                                        pkg.isInstalled
                                            ? pkg.currentVersion
                                            : pkg.latestVersion,
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: tokens.textMuted,
                                      ),
                                    ),
                                    Text(
                                      pkg.isInstalled
                                          ? context.l10n.installed
                                          : context.l10n.available,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: tokens.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Action Buttons Row (Wrap for responsive wrapping)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Every slot is an AnimatedActionWidth, so a
                              // slot whose content changes (Install →
                              // Downloading → Installing → Launch) animates
                              // to its new width instead of jumping.
                              if (pkg.hasUpdate) ...[
                                AnimatedActionWidth(
                                  child: _launchOrUninstalling(
                                    pkg,
                                    primary: false,
                                  ),
                                ),
                                AnimatedActionWidth(
                                  child: SetupActionButton(
                                    icon: FluentIcons.up,
                                    label: context.l10n.updateToVersion(
                                      pkg.latestVersion,
                                    ),
                                    runningStatus: context.l10n.setupUpdating,
                                    inProgress: widget.setupInProgress,
                                    downloadFraction:
                                        widget.setupDownloadFraction,
                                    enabled: !widget.busy,
                                    onPressed: widget.onUpdate,
                                  ),
                                ),
                              ] else if (pkg.isInstalled) ...[
                                AnimatedActionWidth(
                                  child: _launchOrUninstalling(
                                    pkg,
                                    primary: true,
                                  ),
                                ),
                              ] else if (pkg.isDownloading) ...[
                                Button(
                                  onPressed: () {},
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(FluentIcons.cancel, size: 13),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            context.l10n.cancelDownload,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                AnimatedActionWidth(
                                  child: SetupActionButton(
                                    icon: FluentIcons.download,
                                    label: context.l10n.installVersion(
                                      pkg.latestVersion,
                                    ),
                                    runningStatus: context.l10n.setupInstalling,
                                    inProgress: widget.setupInProgress,
                                    downloadFraction:
                                        widget.setupDownloadFraction,
                                    enabled: !widget.busy,
                                    onPressed: widget.onInstall,
                                    focusNode: widget.primaryActionFocus,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (pkg.canUninstall || _hasOtherVersions(pkg))
                          OverflowMenu(
                            triggerLabel: context.l10n.moreOptions,
                            openFolderLabel: pkg.isInstalled
                                ? context.l10n.openInstallFolder
                                : null,
                            installVersionLabel: _hasOtherVersions(pkg)
                                ? context.l10n.installOtherVersion
                                : null,
                            onInstallVersion: widget.busy
                                ? null
                                : widget.onInstallVersion,
                            uninstallLabel: pkg.canUninstall
                                ? context.l10n.uninstall
                                : null,
                            onUninstall: widget.busy
                                ? null
                                : widget.onUninstall,
                            triggerFocus: widget.overflowFocus,
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Divider(
                      style: DividerThemeData(
                        thickness: 1,
                        decoration: BoxDecoration(color: tokens.cardBorder),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // About this software
              Text(
                context.l10n.aboutThisSoftware,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                pkg.subtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pkg.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: tokens.textMuted,
                ),
              ),

              // What's new is hidden until the catalog publishes a release.
              if (pkg.latestRelease.version.isNotEmpty) ...[
                const SizedBox(height: 24),
                Divider(
                  style: DividerThemeData(
                    thickness: 1,
                    decoration: BoxDecoration(color: tokens.cardBorder),
                  ),
                ),
                const SizedBox(height: 18),

                // What's new section
                Text(
                  context.l10n.whatsNew,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.text,
                  ),
                ),
                const SizedBox(height: 12),

                // Latest release notes
                Row(
                  children: [
                    Text(
                      versionLabel(pkg.latestRelease.version),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatUserDate(pkg.latestRelease.date),
                      style: TextStyle(fontSize: 12, color: tokens.textSubtle),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Highlights
              ...pkg.latestRelease.highlights.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 10),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.brandAccent,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          h,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Older releases expander / accordion
              if (pkg.olderReleaseCount > 0) ...[
                HoverButton(
                  onPressed: () {
                    setState(() {
                      _olderExpanded = !_olderExpanded;
                    });
                  },
                  builder: (context, states) {
                    return Semantics(
                      button: true,
                      expanded: _olderExpanded,
                      child: FocusBorder(
                        focused: states.isFocused,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: states.isHovered
                                ? (tokens.hover)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _olderExpanded
                                    ? FluentIcons.chevron_down
                                    : FluentIcons.chevron_right,
                                size: 11,
                                color: tokens.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  context.l10n.olderReleases(
                                    pkg.olderReleaseCount,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                if (_olderExpanded && pkg.hasUnloadedHistory)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 12),
                    child: widget.historyError != null
                        ? Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.l10n.olderReleasesLoadFailed,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Button(
                                onPressed: widget.onRetryHistory,
                                child: Text(context.l10n.retry),
                              ),
                            ],
                          )
                        : const SizedBox(
                            width: 18,
                            height: 18,
                            child: ProgressRing(strokeWidth: 2),
                          ),
                  )
                else if (_olderExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pkg.olderReleases.map((rel) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    versionLabel(rel.version),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatUserDate(rel.date),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: tokens.textSubtle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...rel.highlights.map(
                                (bullet) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                          top: 6,
                                          right: 8,
                                        ),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: tokens.textSubtle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          bullet,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            height: 1.4,
                                            color: tokens.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
