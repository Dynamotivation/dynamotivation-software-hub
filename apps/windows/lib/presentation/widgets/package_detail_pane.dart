import 'package:fluent_ui/fluent_ui.dart';

import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_scroll/hub_scroll.dart';

import '../theme/dynamotivation_theme.dart';
import 'package_image.dart';
import 'overflow_menu.dart';
import 'version_label.dart';

class PackageDetailPane extends StatefulWidget {
  final SoftwarePackage? package;
  final VoidCallback onUpdate;
  final VoidCallback onLaunch;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;
  final FocusNode? primaryActionFocus;
  final FocusNode? overflowFocus;

  const PackageDetailPane({
    super.key,
    required this.package,
    required this.onUpdate,
    required this.onLaunch,
    required this.onInstall,
    required this.onUninstall,
    this.primaryActionFocus,
    this.overflowFocus,
  });

  @override
  State<PackageDetailPane> createState() => _PackageDetailPaneState();
}

class _PackageDetailPaneState extends State<PackageDetailPane> {
  bool _olderExpanded = false;
  String? _selectedVersion;
  final _scroll = SmoothScrollController();

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (pkg.hasUpdate) ...[
                                Button(
                                  focusNode: widget.primaryActionFocus,
                                  onPressed: widget.onLaunch,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(FluentIcons.play, size: 12),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(context.l10n.launch),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: widget.onUpdate,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(FluentIcons.up, size: 13),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            context.l10n.updateToVersion(
                                              pkg.latestVersion,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else if (pkg.isInstalled) ...[
                                FilledButton(
                                  focusNode: widget.primaryActionFocus,
                                  onPressed: widget.onLaunch,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(FluentIcons.play, size: 13),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(context.l10n.launch),
                                        ),
                                      ],
                                    ),
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
                                FilledButton(
                                  focusNode: widget.primaryActionFocus,
                                  onPressed: widget.onInstall,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          FluentIcons.download,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            context.l10n.installVersion(
                                              pkg.latestVersion,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (pkg.isInstalled)
                          OverflowMenu(
                            triggerLabel: context.l10n.moreOptions,
                            openFolderLabel: context.l10n.openInstallFolder,
                            verifyLabel: context.l10n.verifyFiles,
                            uninstallLabel: context.l10n.uninstall,
                            onUninstall: widget.onUninstall,
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
                      pkg.latestRelease.date,
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
              if (pkg.olderReleases.isNotEmpty) ...[
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
                                    pkg.olderReleases.length,
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

                if (_olderExpanded)
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
                                    rel.date,
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
