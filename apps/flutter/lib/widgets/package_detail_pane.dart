import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/l10n.dart';
import '../models/package_model.dart';
import '../theme/dynamotivation_theme.dart';

class PackageDetailPane extends StatefulWidget {
  final SoftwarePackage? package;
  final VoidCallback onUpdate;
  final VoidCallback onLaunch;

  const PackageDetailPane({
    super.key,
    required this.package,
    required this.onUpdate,
    required this.onLaunch,
  });

  @override
  State<PackageDetailPane> createState() => _PackageDetailPaneState();
}

class _PackageDetailPaneState extends State<PackageDetailPane> {
  bool _olderExpanded = false;
  String? _selectedVersion;

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

    if (widget.package == null) {
      return Center(
        child: Text(
          context.l10n.selectPackagePrompt,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? DynTokens.dark.textMuted
                : DynTokens.light.textMuted,
          ),
        ),
      );
    }

    final pkg = widget.package!;
    _selectedVersion ??= pkg.availableVersions.firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? DynTokens.dark.card : DynTokens.light.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? DynTokens.dark.cardBorder
              : DynTokens.light.cardBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Top Header: Icon + Title + Status + Action Buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large package icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x28FFFFFF)
                          : const Color(0x22000000),
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
                  child: pkg.isSvgIcon
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(
                            pkg.iconAsset,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(pkg.iconAsset, fit: BoxFit.cover),
                ),

                const SizedBox(width: 18),

                // Name & Version & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? DynTokens.dark.text
                              : DynTokens.light.text,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status pill + version flow (Wrap for narrow layouts)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (pkg.hasUpdate) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x2EFF6B6B)
                                    : const Color(0x1FE22050),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: DynamotivationTheme.coralPrimary
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    FluentIcons.up,
                                    size: 11,
                                    color: DynTokens.of(context).brandRed,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.l10n.updateAvailable,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: DynTokens.of(context).brandRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'v${pkg.currentVersion}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? DynTokens.dark.textMuted
                                    : DynTokens.light.textMuted,
                              ),
                            ),
                            const Text(
                              '→',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: DynamotivationTheme.coralPrimary,
                              ),
                            ),
                            Text(
                              'v${pkg.latestVersion}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: DynamotivationTheme.coralPrimary,
                              ),
                            ),
                          ] else if (pkg.isInstalled) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x2238E89F)
                                    : const Color(0x1838E89F),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: DynamotivationTheme.mintDark
                                      .withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    FluentIcons.check_mark,
                                    size: 11,
                                    color: DynamotivationTheme.mintDark,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.l10n.installed,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF67FFAE)
                                          : const Color(0xFF0F7A48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'v${pkg.currentVersion}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? DynTokens.dark.textMuted
                                    : DynTokens.light.textMuted,
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x26FFFFFF)
                                    : const Color(0x1F000000),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.l10n.available,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? DynTokens.dark.textMuted
                                      : DynTokens.light.textMuted,
                                ),
                              ),
                            ),
                            Text(
                              'v${pkg.latestVersion}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? DynTokens.dark.textMuted
                                    : DynTokens.light.textMuted,
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
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (pkg.hasUpdate) ...[
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
                          Text(context.l10n.updateToVersion(pkg.latestVersion)),
                        ],
                      ),
                    ),
                  ),
                  Button(
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
                          Text(context.l10n.launch),
                        ],
                      ),
                    ),
                  ),
                ] else if (pkg.isInstalled) ...[
                  FilledButton(
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
                          Text(context.l10n.launch),
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
                          Text(context.l10n.cancelDownload),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: widget.onUpdate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FluentIcons.download, size: 13),
                          const SizedBox(width: 6),
                          Text(context.l10n.installVersion(pkg.latestVersion)),
                        ],
                      ),
                    ),
                  ),
                ],

                // More options dropdown
                DropDownButton(
                  title: const Icon(FluentIcons.more, size: 14),
                  items: [
                    MenuFlyoutItem(
                      leading: const Icon(
                        FluentIcons.open_folder_horizontal,
                        size: 14,
                      ),
                      text: Text(context.l10n.openInstallFolder),
                      onPressed: () {},
                    ),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.verified_brand, size: 14),
                      text: Text(context.l10n.verifyFiles),
                      onPressed: () {},
                    ),
                    const MenuFlyoutSeparator(),
                    MenuFlyoutItem(
                      leading: const Icon(
                        FluentIcons.delete,
                        size: 14,
                        color: Color(0xFFC42B1C),
                      ),
                      text: Text(
                        context.l10n.uninstall,
                        style: TextStyle(color: Color(0xFFC42B1C)),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(
              style: DividerThemeData(
                thickness: 1,
                decoration: BoxDecoration(
                  color: isDark
                      ? DynTokens.dark.cardBorder
                      : const Color(0x18000000),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // About this software
            Text(
              context.l10n.aboutThisSoftware,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? DynTokens.dark.text : DynTokens.light.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pkg.subtitle,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFE2E4EB)
                    : const Color(0xFF282B33),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pkg.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? DynTokens.dark.textMuted
                    : const Color(0xFF5A5D6B),
              ),
            ),

            const SizedBox(height: 24),
            Divider(
              style: DividerThemeData(
                thickness: 1,
                decoration: BoxDecoration(
                  color: isDark
                      ? DynTokens.dark.cardBorder
                      : const Color(0x18000000),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // What's new section
            Text(
              context.l10n.whatsNew,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? DynTokens.dark.text : DynTokens.light.text,
              ),
            ),
            const SizedBox(height: 12),

            // Latest release notes
            Row(
              children: [
                Text(
                  'v${pkg.latestRelease.version}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? DynTokens.dark.text : DynTokens.light.text,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  pkg.latestRelease.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF8A8D99)
                        : const Color(0xFF828594),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

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
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: DynamotivationTheme.coralPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: isDark
                              ? DynTokens.dark.textMuted
                              : DynTokens.light.textMuted,
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
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: states.isHovered
                          ? (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04))
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
                          color: isDark
                              ? DynTokens.dark.textMuted
                              : DynTokens.light.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.olderReleases(pkg.olderReleases.length),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? DynTokens.dark.textMuted
                                : DynTokens.light.textMuted,
                          ),
                        ),
                      ],
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
                                  'v${rel.version}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? DynTokens.dark.textMuted
                                        : DynTokens.light.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  rel.date,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF8A8D99)
                                        : const Color(0xFF828594),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...rel.highlights.map(
                              (bullet) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: isDark
                                            ? const Color(0xFF8A8D99)
                                            : const Color(0xFF828594),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        bullet,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: isDark
                                              ? DynTokens.dark.textMuted
                                              : DynTokens.light.textMuted,
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
    );
  }
}
