import 'package:flutter/material.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_scroll/hub_scroll.dart';

import '../theme/dynamotivation_ubuntu_theme.dart';
import 'package_icon.dart';

class PackageDetailView extends StatelessWidget {
  final SoftwarePackage? package;
  final ScrollController scrollController;
  final VoidCallback onUpdate;
  final VoidCallback onLaunch;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const PackageDetailView({
    super.key,
    required this.package,
    required this.scrollController,
    required this.onUpdate,
    required this.onLaunch,
    required this.onInstall,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final pkg = package;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (pkg == null) {
      return Center(
        child: Text(
          l10n.selectPackagePrompt,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return Column(
      children: [
        _UbuntuBanner(
          package: pkg,
          onUpdate: onUpdate,
          onLaunch: onLaunch,
          onInstall: onInstall,
          onUninstall: onUninstall,
        ),
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            child: SmoothScroll(
              controller: scrollController,
              child: ListView(
                controller: scrollController,
                physics: smoothScrollPhysics,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                children: [
                  _UbuntuCard(
                    title: l10n.aboutThisSoftware,
                    icon: Icons.info_outline,
                    child: Text(
                      pkg.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _UbuntuCard(
                    title: l10n.whatsNew,
                    icon: Icons.new_releases_outlined,
                    trailingText: 'v${pkg.latestVersion}',
                    child: _ReleaseNotesView(note: pkg.latestRelease),
                  ),
                  if (pkg.olderReleases.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _UbuntuCard(
                      title: l10n.olderReleases(pkg.olderReleases.length),
                      icon: Icons.history,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final release in pkg.olderReleases) ...[
                            _ReleaseNotesView(note: release),
                            if (release != pkg.olderReleases.last)
                              const Divider(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _UbuntuCard(
                    title: l10n.packageDetails,
                    icon: Icons.tune,
                    child: _PackageMetadataTable(package: pkg),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UbuntuBanner extends StatelessWidget {
  final SoftwarePackage package;
  final VoidCallback onUpdate;
  final VoidCallback onLaunch;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const _UbuntuBanner({
    required this.package,
    required this.onUpdate,
    required this.onLaunch,
    required this.onInstall,
    required this.onUninstall,
  });

  Future<void> _confirmUninstall(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.uninstallConfirmTitle(package.name)),
        content: Text(l10n.uninstallConfirmBody),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DynUbuntuTheme.crimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.uninstall),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onUninstall();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = package.isInstalled ? l10n.installed : l10n.available;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
      decoration: const BoxDecoration(
        gradient: DynUbuntuTheme.fusedHeaderGradient,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PackageIcon(package: package, size: 76),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  package.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  package.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  package.hasUpdate
                      ? 'v${package.currentVersion} → v${package.latestVersion} · $status'
                      : 'v${package.currentVersion} · $status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: package.hasUpdate ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons & 3-dot overflow menu for destructive actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          if (!package.isInstalled)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: onInstall,
                              icon: const Icon(Icons.download, size: 18),
                              label: Text(
                                l10n.installVersion(package.latestVersion),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (package.isInstalled)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: package.hasUpdate
                                    ? Colors.white24
                                    : theme.colorScheme.primary,
                                foregroundColor: package.hasUpdate
                                    ? Colors.white
                                    : theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: onLaunch,
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: Text(
                                l10n.launch,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (package.hasUpdate)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: onUpdate,
                              icon: const Icon(Icons.arrow_circle_up, size: 18),
                              label: Text(
                                l10n.updateToVersion(package.latestVersion),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (package.isInstalled)
                      PopupMenuButton<String>(
                        tooltip: l10n.moreOptions,
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onSelected: (val) {
                          if (val == 'uninstall') {
                            _confirmUninstall(context);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'uninstall',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Text('${l10n.uninstall}…'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UbuntuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? trailingText;
  final Widget child;

  const _UbuntuCard({
    required this.title,
    required this.icon,
    this.trailingText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? DynUbuntuTheme.cardDark : DynUbuntuTheme.cardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? DynUbuntuTheme.cardBorderDark
              : DynUbuntuTheme.cardBorderLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailingText != null) ...[
                const Spacer(),
                Text(
                  trailingText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReleaseNotesView extends StatelessWidget {
  final ReleaseNote note;

  const _ReleaseNotesView({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.versionLabel(note.version),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '· ${note.date}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final highlight in note.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    highlight,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PackageMetadataTable extends StatelessWidget {
  final SoftwarePackage package;

  const _PackageMetadataTable({required this.package});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? Colors.white60 : Colors.black54;
    final l10n = context.l10n;

    return Column(
      children: [
        _MetadataRow(
          label: l10n.packageId,
          value: package.id,
          secondaryColor: secondary,
        ),
        const Divider(height: 16),
        _MetadataRow(
          label: l10n.installedVersion,
          value: package.isInstalled ? 'v${package.currentVersion}' : l10n.none,
          secondaryColor: secondary,
        ),
        const Divider(height: 16),
        _MetadataRow(
          label: l10n.availableVersion,
          value: 'v${package.latestVersion}',
          secondaryColor: secondary,
        ),
        const Divider(height: 16),
        _MetadataRow(
          label: l10n.status,
          value: package.isInstalled ? l10n.installed : l10n.available,
          secondaryColor: secondary,
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color secondaryColor;

  const _MetadataRow({
    required this.label,
    required this.value,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: secondaryColor, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
