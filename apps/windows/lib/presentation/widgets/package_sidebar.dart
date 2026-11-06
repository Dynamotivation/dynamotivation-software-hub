import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart';

import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_keys/hub_keys.dart';
import 'package:hub_scroll/hub_scroll.dart';

import '../shortcuts.dart';
import 'package_image.dart';
import 'accessible_icon_button.dart';
import 'version_label.dart';
import '../theme/dynamotivation_theme.dart';
import 'click_cursor.dart';

class PackageSidebar extends StatefulWidget {
  final List<SoftwarePackage> packages;
  final Set<String> departingIds;
  final SoftwarePackage? selectedPackage;
  final ValueChanged<SoftwarePackage> onSelectPackage;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final FocusNode? searchFocusNode;

  const PackageSidebar({
    super.key,
    required this.packages,
    this.departingIds = const {},
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
  final _scroll = SmoothScrollController();

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
    if (MediaQuery.disableAnimationsOf(context)) {
      _spinController.stop();
      _spinController.reset();
    } else if (widget.isRefreshing && !oldWidget.isRefreshing) {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spinController.stop();
      _spinController.reset();
    } else if (widget.isRefreshing && !_spinController.isAnimating) {
      _spinController.repeat();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _spinController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// A tile that fades out and collapses while its package is departing.
  Widget _tile(SoftwarePackage pkg) {
    final departing = widget.departingIds.contains(pkg.id);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return AnimatedSize(
      key: ValueKey(pkg.id),
      duration: duration,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: departing
          ? const SizedBox(width: double.infinity)
          : _PackageTile(
              package: pkg,
              isSelected: widget.selectedPackage?.id == pkg.id,
              onTap: () => widget.onSelectPackage(pkg),
            ),
    );
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
            child: Row(
              children: [
                Expanded(
                  // Fluent's placeholder names the empty field only. Supply
                  // the same name when populated without duplicating it empty.
                  child: MergeSemantics(
                    child: Semantics(
                      label: _searchController.text.isEmpty
                          ? null
                          : context.l10n.searchSoftware,
                      child: TextBox(
                        controller: _searchController,
                        focusNode: widget.searchFocusNode,
                        placeholder: context.l10n.searchSoftware,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 6),
                          child: Icon(FluentIcons.search, size: 14),
                        ),
                        onChanged: widget.onSearchChanged,
                      ),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  AccessibleIconButton(
                    label: context.l10n.clearSearch,
                    icon: const Icon(FluentIcons.clear, size: 12),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchChanged('');
                      widget.searchFocusNode?.requestFocus();
                    },
                  ),
              ],
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
                          child: ClickIconButton(
                            icon: Semantics(
                              label: context.l10n.checkForUpdates,
                              child: RotationTransition(
                                turns: _spinController,
                                child: const SpinnableRefreshIcon(size: 14),
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
                    cursor: SystemMouseCursors.click,
                    onPressed: () {
                      setState(() {
                        _availableExpanded = !_availableExpanded;
                      });
                    },
                    builder: (context, states) {
                      return Semantics(
                        button: true,
                        expanded: _availableExpanded,
                        child: FocusBorder(
                          focused: states.isFocused,
                          child: Container(
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
                          ),
                        ),
                      );
                    },
                  ),

                  // Available list items
                  if (_availableExpanded)
                    ...availableList.map((pkg) => _tile(pkg)),
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
        ? (MediaQuery.highContrastOf(context)
              ? tokens.text
              : tokens.primary.withValues(alpha: 0.4))
        : Colors.transparent;

    return HoverButton(
      cursor: SystemMouseCursors.click,
      key: ValueKey('package-${package.id}'),
      onPressed: onTap,
      builder: (context, states) {
        final isHover = states.isHovered;
        return Semantics(
          button: true,
          selected: isSelected,
          label: isSelected ? context.l10n.selectedPackage : null,
          child: FocusBorder(
            focused: states.isFocused,
            child: Container(
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
                    child: packageImage(package, BoxFit.cover),
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
                            versionLabel(package.currentVersion),
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.textMuted,
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
            ),
          ),
        );
      },
    );
  }
}

/// Refresh arrow built to be spun: a ring centred exactly on the pivot with a
/// small filled arrowhead, all inside a circle that fits the paint area, so no
/// angle crops it or shifts its centre. Font and SVG glyphs put a detached
/// arrowhead in a corner, which swings outside the ring while turning.
///
/// Lays out as [size] square but paints on a larger canvas so the arrowhead is
/// never clipped.
class SpinnableRefreshIcon extends StatelessWidget {
  final double size;

  const SpinnableRefreshIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = DynTokens.of(context).textMuted;
    final canvas = size * 1.4;
    return SizedBox.square(
      dimension: size,
      child: OverflowBox(
        maxWidth: canvas,
        maxHeight: canvas,
        child: ExcludeSemantics(
          child: CustomPaint(
            size: Size.square(canvas),
            painter: _RefreshRingPainter(color),
          ),
        ),
      ),
    );
  }
}

class _RefreshRingPainter extends CustomPainter {
  final Color color;

  const _RefreshRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 20; // designed on a 20 x 20 grid
    final c = size.center(Offset.zero);
    final r = 6.5 * unit;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * unit
      ..strokeCap = StrokeCap.round;
    const start = -28 * math.pi / 180;
    const sweep = 290 * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      stroke,
    );

    // Filled arrowhead on the arc's end, pointing along the clockwise travel.
    const end = start + sweep;
    final radial = Offset(math.cos(end), math.sin(end));
    final tangent = Offset(-math.sin(end), math.cos(end));
    final base = c + radial * r;
    final head = Path()
      ..moveTo(
        (base + tangent * 3.4 * unit).dx,
        (base + tangent * 3.4 * unit).dy,
      )
      ..lineTo((base + radial * 2.6 * unit).dx, (base + radial * 2.6 * unit).dy)
      ..lineTo((base - radial * 2.6 * unit).dx, (base - radial * 2.6 * unit).dy)
      ..close();
    canvas.drawPath(
      head,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RefreshRingPainter old) => old.color != color;
}
