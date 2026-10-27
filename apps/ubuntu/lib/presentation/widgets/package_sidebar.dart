import 'package:flutter/material.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_scroll/hub_scroll.dart';

import '../theme/dynamotivation_ubuntu_theme.dart';
import 'brand_lockup.dart';
import 'package_icon.dart';

/// Ubuntu Yaru master-detail sidebar list for packages.
/// Fixed horizontal layout: rows never shift on selection.
/// Clean typography without decorative pill badges.
class PackageSidebar extends StatefulWidget {
  final List<SoftwarePackage> packages;
  final SoftwarePackage? selectedPackage;
  final ValueChanged<SoftwarePackage> onSelectPackage;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final FocusNode searchFocusNode;

  const PackageSidebar({
    super.key,
    required this.packages,
    required this.selectedPackage,
    required this.onSelectPackage,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.searchFocusNode,
  });

  @override
  State<PackageSidebar> createState() => _PackageSidebarState();
}

class _PackageSidebarState extends State<PackageSidebar> {
  late final TextEditingController _searchController;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant PackageSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final query = widget.searchQuery.trim().toLowerCase();
    final filtered = widget.packages.where((pkg) {
      if (query.isEmpty) return true;
      return pkg.name.toLowerCase().contains(query) ||
          pkg.subtitle.toLowerCase().contains(query) ||
          pkg.description.toLowerCase().contains(query);
    }).toList();

    final installed = filtered.where((p) => p.isInstalled).toList();
    final available = filtered.where((p) => !p.isInstalled).toList();

    final sidebarBg = isDark
        ? DynUbuntuTheme.sidebarDark
        : DynUbuntuTheme.sidebarLight;
    final borderColor = isDark
        ? DynUbuntuTheme.cardBorderDark
        : DynUbuntuTheme.cardBorderLight;

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandLockup(),

          // Search Field in Ubuntu style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              focusNode: widget.searchFocusNode,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.searchSoftware,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: theme.colorScheme.onSurface.withValues(
                  alpha: isDark ? 0.12 : 0.04,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Scrollable package list using SmoothScroll
          Expanded(
            child: SmoothScroll(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                physics: smoothScrollPhysics,
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (installed.isNotEmpty) ...[
                      _CategoryHeader(
                        title: l10n.installed,
                        count: installed.length,
                      ),
                      for (final pkg in installed)
                        _UbuntuPackageTile(
                          package: pkg,
                          selected: pkg.id == widget.selectedPackage?.id,
                          onTap: () => widget.onSelectPackage(pkg),
                        ),
                    ],
                    if (available.isNotEmpty) ...[
                      _CategoryHeader(
                        title: l10n.available,
                        count: available.length,
                      ),
                      for (final pkg in available)
                        _UbuntuPackageTile(
                          package: pkg,
                          selected: pkg.id == widget.selectedPackage?.id,
                          onTap: () => widget.onSelectPackage(pkg),
                        ),
                    ],
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            l10n.selectPackagePrompt,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final int count;

  const _CategoryHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
        child: Text(
          '$title  $count',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _UbuntuPackageTile extends StatefulWidget {
  final SoftwarePackage package;
  final bool selected;
  final VoidCallback onTap;

  const _UbuntuPackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_UbuntuPackageTile> createState() => _UbuntuPackageTileState();
}

class _UbuntuPackageTileState extends State<_UbuntuPackageTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pkg = widget.package;
    final selected = widget.selected;

    Color bg;
    if (selected) {
      bg = theme.colorScheme.primary.withValues(
        alpha: isDark ? 0.20 : 0.13,
      );
    } else if (_hovered) {
      bg = theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.05);
    } else {
      bg = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                PackageIcon(package: pkg, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pkg.name,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (pkg.hasUpdate)
                            Text(
                              'v${pkg.latestVersion}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pkg.subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
