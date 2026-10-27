import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_scroll/hub_scroll.dart';
import 'package:macos_ui/macos_ui.dart';

import '../theme/dynamotivation_macos_theme.dart';
import 'package_icon.dart';

/// Source list with "Installed" and "Available" sections and two-line rows
/// (name, version). Written by hand because [SidebarItems] rows are a fixed
/// single line of 24-32pt and cannot show a version.
class PackageList extends StatelessWidget {
  final List<SoftwarePackage> packages;
  final SoftwarePackage? selected;
  final ValueChanged<SoftwarePackage> onSelect;
  final ScrollController controller;

  const PackageList({
    super.key,
    required this.packages,
    required this.selected,
    required this.onSelect,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final installed = packages.where((p) => p.isInstalled).toList();
    final available = packages.where((p) => !p.isInstalled).toList();

    return MacosScrollbar(
      controller: controller,
      child: SmoothScroll(
        controller: controller,
        child: ListView(
          controller: controller,
          physics: smoothScrollPhysics,
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          children: [
            if (installed.isNotEmpty) ...[
              _SectionHeader(title: l10n.installed, count: installed.length),
              for (final p in installed)
                _PackageRow(
                  package: p,
                  selected: p.id == selected?.id,
                  onTap: () => onSelect(p),
                ),
            ],
            if (available.isNotEmpty) ...[
              _SectionHeader(title: l10n.available, count: available.length),
              for (final p in available)
                _PackageRow(
                  package: p,
                  selected: p.id == selected?.id,
                  onTap: () => onSelect(p),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
        child: Text(
          '$title  $count',
          // Secondary label colour, 60%: >= 5:1 on the sidebar surface.
          style: typography.caption1.copyWith(
            fontWeight: FontWeight.w600,
            color: typography.caption1.color?.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _PackageRow extends StatefulWidget {
  final SoftwarePackage package;
  final bool selected;
  final VoidCallback onTap;

  const _PackageRow({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PackageRow> createState() => _PackageRowState();
}

class _PackageRowState extends State<_PackageRow> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final isDark = theme.brightness.isDark;
    final p = widget.package;
    final selected = widget.selected;

    // Selected rows are solid brand colour with white text (4.6:1); other
    // rows use label colours, and the version of a pending update uses a
    // darker/lighter brand red so it keeps >= 4.5:1 on the sidebar.
    const onAccent = Color(0xFFFFFFFF);
    final primary = selected ? onAccent : theme.typography.body.color;
    final secondary = selected
        ? onAccent
        : theme.typography.body.color?.withValues(alpha: 0.6);
    final updateColor = isDark ? const Color(0xFFFF6B6B) : DynBrand.accentDark;

    final version = p.isInstalled
        ? 'v${p.currentVersion}'
        : 'v${p.latestVersion}';
    final semanticsLabel = [
      p.name,
      version,
      if (p.hasUpdate) context.l10n.updateToVersion(p.latestVersion),
    ].join(', ');

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? DynBrand.accent
                  : (_hover
                        ? (isDark
                              ? const Color(0x14FFFFFF)
                              : const Color(0x0F000000))
                        : const Color(0x00000000)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                // Keyboard focus ring: 2px, label colour.
                color: _focus
                    ? (isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000))
                    : const Color(0x00000000),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                PackageIcon(package: p, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.body.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text.rich(
                        TextSpan(
                          style: theme.typography.caption1.copyWith(
                            color: secondary,
                          ),
                          children: [
                            TextSpan(text: version),
                            if (p.hasUpdate)
                              TextSpan(
                                text: '  → v${p.latestVersion}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected ? onAccent : updateColor,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
