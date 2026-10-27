import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_scroll/hub_scroll.dart';
import 'package:macos_ui/macos_ui.dart';

import '../theme/dynamotivation_macos_theme.dart';
import 'glass_controls.dart';
import 'package_icon.dart';

class PackageDetailView extends StatelessWidget {
  final SoftwarePackage? package;
  final ScrollController scrollController;
  final VoidCallback onUpdate;
  final VoidCallback onLaunch;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  /// Space above the banner content (room for floating actions off macOS).
  final double topInset;

  const PackageDetailView({
    super.key,
    required this.package,
    required this.scrollController,
    required this.onUpdate,
    required this.onLaunch,
    required this.onInstall,
    required this.onUninstall,
    this.topInset = 56,
  });

  @override
  Widget build(BuildContext context) {
    final pkg = package;
    final theme = MacosTheme.of(context);
    final l10n = context.l10n;
    if (pkg == null) {
      return Center(
        child: Text(l10n.selectPackagePrompt, style: theme.typography.title3),
      );
    }

    // The banner stays put; only the content below it scrolls.
    return Column(
      children: [
        _Header(
          package: pkg,
          onUpdate: onUpdate,
          onLaunch: onLaunch,
          onInstall: onInstall,
          onUninstall: onUninstall,
          topInset: topInset,
        ),
        Expanded(
          child: SmoothScroll(
            controller: scrollController,
            child: ListView(
              controller: scrollController,
              physics: smoothScrollPhysics,
              padding: EdgeInsets.zero,
              children: [
                // Soft fade from the banner into the page.
                const SizedBox(
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x26893750), Color(0x00893750)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section(
                        title: l10n.aboutThisSoftware,
                        child: Text(
                          pkg.description,
                          style: theme.typography.body,
                        ),
                      ),
                      _Section(
                        title: l10n.whatsNew,
                        child: _ReleaseNotes(note: pkg.latestRelease),
                      ),
                      if (pkg.olderReleases.isNotEmpty)
                        _Section(
                          title: l10n.olderReleases(pkg.olderReleases.length),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final note in pkg.olderReleases) ...[
                                _ReleaseNotes(note: note),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ),
                        ),
                    ],
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

class _Header extends StatelessWidget {
  final SoftwarePackage package;
  final VoidCallback onUpdate;
  final VoidCallback onLaunch;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;
  final double topInset;

  const _Header({
    required this.package,
    required this.onUpdate,
    required this.onLaunch,
    required this.onInstall,
    required this.onUninstall,
    required this.topInset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = MacosTheme.of(context);
    const white = Color(0xFFFFFFFF);
    final status = switch (package.status) {
      PackageInstallationStatus.updateAvailable => l10n.updateAvailable,
      PackageInstallationStatus.installed => l10n.installed,
      _ => l10n.available,
    };

    // Windows high-contrast mode: drop the gradient for a flat dark fill.
    final highContrast = MediaQuery.highContrastOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highContrast ? DynBrand.maroon : null,
        gradient: highContrast ? null : DynBrand.headerGradient,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, topInset, 28, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: PackageIcon(package: package, size: 116),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      package.name,
                      style: theme.typography.largeTitle.copyWith(
                        color: white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    package.subtitle,
                    style: theme.typography.title3.copyWith(color: white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    package.hasUpdate
                        ? 'v${package.currentVersion} → '
                              'v${package.latestVersion} · $status'
                        : 'v${package.currentVersion} · $status',
                    style: theme.typography.callout.copyWith(
                      color: white,
                      fontWeight: package.hasUpdate
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (!package.isInstalled && !package.isDownloading)
                              PushButton(
                                controlSize: ControlSize.large,
                                onPressed: onInstall,
                                child: Text(
                                  l10n.installVersion(package.latestVersion),
                                ),
                              ),
                            if (package.isInstalled)
                              PushButton(
                                controlSize: ControlSize.large,
                                secondary: package.hasUpdate,
                                onPressed: onLaunch,
                                child: Text(l10n.launch),
                              ),
                            if (package.hasUpdate)
                              PushButton(
                                controlSize: ControlSize.large,
                                onPressed: onUpdate,
                                child: Text(
                                  l10n.updateToVersion(package.latestVersion),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (package.isInstalled)
                        MoreMenuButton(
                          label: l10n.moreOptions,
                          entries: [
                            MoreMenuEntry(
                              label: '${l10n.uninstall}…',
                              onSelected: onUninstall,
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
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.typography.title2),
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: theme.dividerColor),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  final ReleaseNote note;

  const _ReleaseNotes({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'v${note.version}  ·  ${note.date}',
          style: theme.typography.headline,
        ),
        const SizedBox(height: 6),
        for (final h in note.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: theme.typography.body),
                Expanded(child: Text(h, style: theme.typography.body)),
              ],
            ),
          ),
      ],
    );
  }
}
