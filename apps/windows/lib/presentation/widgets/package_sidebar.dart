import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_keys/hub_keys.dart';
import 'package:hub_scroll/hub_scroll.dart';

import '../shortcuts.dart';
import '../theme/dynamotivation_theme.dart';

class PackageSidebar extends StatefulWidget {
  final List<SoftwarePackage> packages;
  final SoftwarePackage? selectedPackage;
  final ValueChanged<SoftwarePackage> onSelectPackage;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final bool isRefreshing;
  final FocusNode? searchFocusNode;

  const PackageSidebar({
    super.key,
    required this.packages,
    required this.selectedPackage,
    required this.onSelectPackage,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    this.isRefreshing = false,
    this.searchFocusNode,
  });

  @override
  State<PackageSidebar> createState() => _PackageSidebarState();
}

class _PackageSidebarState extends State<PackageSidebar>
    with SingleTickerProviderStateMixin {
  bool _availableExpanded = true;
  late TextEditingController _searchController;
  late AnimationController _spinController;
  final _scroll = ScrollController();

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
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _spinController.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      // Finish the turn in progress instead of snapping back, so even an
      // instant refresh shows one smooth rotation.
      final remaining = 1 - _spinController.value;
      _spinController
          .animateTo(
            1,
            duration: Duration(milliseconds: (900 * remaining).round()),
            curve: Curves.easeOut,
          )
          .whenComplete(() {
            if (mounted && !widget.isRefreshing) _spinController.reset();
          });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _spinController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);

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
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          // Search box area
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: TextBox(
              controller: _searchController,
              focusNode: widget.searchFocusNode,
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
            ),
          ),

          // Scrollable package lists
          Expanded(
            child: SmoothScroll(
              controller: _scroll,
              child: ListView(
                controller: _scroll,
                physics: smoothScrollPhysics,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                children: [
                  // Installed section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.l10n.installed,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.hover,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${installedList.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: withShortcut(
                            context.l10n.checkForUpdates,
                            AppShortcuts.refresh,
                          ),
                          child: IconButton(
                            icon: RotationTransition(
                              turns: _spinController,
                              // Painted around its exact centre; a font glyph
                              // is off-centre in its box and wobbles when spun.
                              child: CustomPaint(
                                size: const Size.square(14),
                                painter: _RefreshGlyphPainter(tokens.textMuted),
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
                      horizontalMargin: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      thickness: 1,
                      decoration: BoxDecoration(color: tokens.divider),
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
                              ? (tokens.hover)
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
                              color: tokens.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.available,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.hover,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${availableList.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textMuted,
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
    final tokens = DynTokens.of(context);

    final tileBg = isSelected ? (tokens.selected) : Colors.transparent;

    final tileBorder = isSelected
        ? (tokens.primary.withValues(alpha: 0.4))
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
                : (isHover ? (tokens.hover) : Colors.transparent),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected
                  ? tileBorder
                  : (isHover ? (tokens.cardBorder) : Colors.transparent),
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
                  border: Border.all(color: tokens.cardBorder, width: 1),
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
                        color: tokens.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (package.hasUpdate)
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.textMuted,
                          ),
                          children: [
                            TextSpan(text: 'v${package.currentVersion} '),
                            TextSpan(
                              text: '→ v${package.latestVersion}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: DynTokens.of(context).brandRed,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'v${package.currentVersion}',
                        style: TextStyle(fontSize: 11, color: tokens.textMuted),
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

/// Circular refresh arrow centred exactly on its box.
class _RefreshGlyphPainter extends CustomPainter {
  final Color color;

  const _RefreshGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1.5;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const start = -math.pi / 2 + 0.5;
    const sweep = math.pi * 2 - 1.3;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      stroke,
    );
    // Arrow head at the end of the arc, pointing along the direction of travel.
    final end = start + sweep;
    final tip = c + Offset(math.cos(end), math.sin(end)) * r;
    final tangent = Offset(-math.sin(end), math.cos(end));
    final normal = Offset(math.cos(end), math.sin(end));
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        (tip - tangent * 3.2 + normal * 3).dx,
        (tip - tangent * 3.2 + normal * 3).dy,
      )
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        (tip - tangent * 3.2 - normal * 3).dx,
        (tip - tangent * 3.2 - normal * 3).dy,
      );
    canvas.drawPath(head, stroke);
  }

  @override
  bool shouldRepaint(_RefreshGlyphPainter old) => old.color != color;
}
