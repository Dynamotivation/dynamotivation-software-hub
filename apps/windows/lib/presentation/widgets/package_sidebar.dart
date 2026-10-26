import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_core/hub_core.dart';

import '../theme/dynamotivation_theme.dart';

class PackageSidebar extends StatefulWidget {
  final List<SoftwarePackage> packages;
  final SoftwarePackage? selectedPackage;
  final ValueChanged<SoftwarePackage> onSelectPackage;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const PackageSidebar({
    super.key,
    required this.packages,
    required this.selectedPackage,
    required this.onSelectPackage,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  State<PackageSidebar> createState() => _PackageSidebarState();
}

class _PackageSidebarState extends State<PackageSidebar>
    with SingleTickerProviderStateMixin {
  bool _availableExpanded = true;
  late TextEditingController _searchController;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant PackageSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
    if (widget.isRefreshing && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!widget.isRefreshing && _spinController.isAnimating) {
      _spinController.stop();
      _spinController.reset();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = widget.searchQuery.trim().toLowerCase();
    final filtered = widget.packages.where((pkg) {
      if (query.isEmpty) return true;
      return pkg.name.toLowerCase().contains(query) ||
          pkg.subtitle.toLowerCase().contains(query) ||
          pkg.description.toLowerCase().contains(query);
    }).toList();

    final installedList = filtered.where((p) => p.isInstalled).toList();
    final availableList = filtered.where((p) => !p.isInstalled).toList();

    return Container(
      width: 320,
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
      child: Column(
        children: [
          // Search box area
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: TextBox(
              controller: _searchController,
              placeholder: context.l10n.searchSoftware,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 10, right: 6),
                child: Icon(FluentIcons.search, size: 14),
              ),
              suffix: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(FluentIcons.clear, size: 12),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              onChanged: widget.onSearchChanged,
              decoration: WidgetStateProperty.all(
                BoxDecoration(
                  color: isDark
                      ? const Color(0x28FFFFFF)
                      : const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0x2EFFFFFF)
                        : const Color(0x2A000000),
                  ),
                ),
              ),
            ),
          ),

          // Scrollable package lists
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                // Installed section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                  child: Row(
                    children: [
                      Text(
                        context.l10n.installed,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? DynTokens.dark.textMuted
                              : DynTokens.light.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x26FFFFFF)
                              : const Color(0x1F000000),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${installedList.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? DynTokens.dark.textMuted
                                : DynTokens.light.textMuted,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: context.l10n.checkForUpdates,
                        child: IconButton(
                          icon: RotationTransition(
                            turns: _spinController,
                            child: Icon(
                              FluentIcons.refresh,
                              size: 13,
                              color: isDark
                                  ? DynTokens.dark.textMuted
                                  : DynTokens.light.textMuted,
                            ),
                          ),
                          onPressed: widget.onRefresh,
                        ),
                      ),
                    ],
                  ),
                ),

                // Installed list items
                ...installedList.map(
                  (pkg) => _PackageTile(
                    package: pkg,
                    isSelected: widget.selectedPackage?.id == pkg.id,
                    onTap: () => widget.onSelectPackage(pkg),
                  ),
                ),

                const SizedBox(height: 10),
                Divider(
                  style: DividerThemeData(
                    horizontalMargin: const EdgeInsets.symmetric(horizontal: 6),
                    thickness: 1,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x14FFFFFF)
                          : const Color(0x14000000),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Available section header (collapsible)
                HoverButton(
                  onPressed: () {
                    setState(() {
                      _availableExpanded = !_availableExpanded;
                    });
                  },
                  builder: (context, states) {
                    return Container(
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: states.isHovered
                            ? (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _availableExpanded
                                ? FluentIcons.chevron_down
                                : FluentIcons.chevron_right,
                            size: 11,
                            color: isDark
                                ? DynTokens.dark.textMuted
                                : DynTokens.light.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.available,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? DynTokens.dark.textMuted
                                  : DynTokens.light.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0x26FFFFFF)
                                  : const Color(0x1F000000),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${availableList.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? DynTokens.dark.textMuted
                                    : DynTokens.light.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Available list items
                if (_availableExpanded)
                  ...availableList.map(
                    (pkg) => _PackageTile(
                      package: pkg,
                      isSelected: widget.selectedPackage?.id == pkg.id,
                      onTap: () => widget.onSelectPackage(pkg),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final SoftwarePackage package;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageTile({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tileBg = isSelected
        ? (isDark ? const Color(0x28FFFFFF) : DynTokens.light.selected)
        : Colors.transparent;

    final tileBorder = isSelected
        ? (isDark ? const Color(0x40FFFFFF) : const Color(0x3B893750))
        : Colors.transparent;

    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        final isHover = states.isHovered;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? tileBg
                : (isHover
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0x14893750))
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected
                  ? tileBorder
                  : (isHover
                        ? (isDark
                              ? DynTokens.dark.cardBorder
                              : const Color(0x18000000))
                        : Colors.transparent),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Package App Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0x28FFFFFF)
                        : DynTokens.light.cardBorder,
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: package.isSvgIcon
                    ? Padding(
                        padding: const EdgeInsets.all(4),
                        child: SvgPicture.asset(
                          package.iconAsset,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(package.iconAsset, fit: BoxFit.cover),
              ),

              const SizedBox(width: 10),

              // Title and version
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      package.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isDark
                            ? DynTokens.dark.text
                            : DynTokens.light.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (package.hasUpdate)
                      Row(
                        children: [
                          Text(
                            'v${package.currentVersion} ',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? DynTokens.dark.textMuted
                                  : DynTokens.light.textMuted,
                            ),
                          ),
                          Text(
                            '→ ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: DynTokens.of(context).brandRed,
                            ),
                          ),
                          Text(
                            'v${package.latestVersion}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: DynTokens.of(context).brandRed,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'v${package.currentVersion}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? DynTokens.dark.textMuted
                              : DynTokens.light.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

              // Downloading indicator or status pip
              if (package.isDownloading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: ProgressRing(
                    value: package.downloadProgress * 100,
                    strokeWidth: 2.2,
                    activeColor: DynamotivationTheme.coralPrimary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
