import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hub_keys/hub_keys.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:yaru/yaru.dart';

import '../shortcuts.dart';
import '../theme/dynamotivation_ubuntu_theme.dart';

/// Window title bar width over the package sidebar; must stay in sync with
/// the sidebar in [PackageSidebar].
const kUbuntuPaneWidth = 290.0;

/// Ubuntu Yaru window title bar arrangement, following the pattern used by
/// the official Ubuntu App Center: a pane-width undecorated drag region over
/// the sidebar, a divider, and the decorated title bar holding the title,
/// navigation and actions. Window controls, dragging, double-click maximize
/// and (on Linux) the window menu are provided by `YaruWindowTitleBar`.
/// Follows single-logo rule (no duplicate logo in header bar; brand lockup stays in sidebar).
class UbuntuHeaderBar extends StatefulWidget {
  final bool isSettingsOpen;
  final VoidCallback onToggleSettings;
  final VoidCallback onRefresh;
  final bool isRefreshing;
  final VoidCallback onFocusSearch;

  const UbuntuHeaderBar({
    super.key,
    required this.isSettingsOpen,
    required this.onToggleSettings,
    required this.onRefresh,
    this.isRefreshing = false,
    required this.onFocusSearch,
  });

  @override
  State<UbuntuHeaderBar> createState() => _UbuntuHeaderBarState();
}

class _UbuntuHeaderBarState extends State<UbuntuHeaderBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(covariant UbuntuHeaderBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _spinController.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      final remaining = 1 - _spinController.value;
      _spinController
          .animateTo(
            1,
            duration: Duration(milliseconds: (800 * remaining).round()),
            curve: Curves.easeOut,
          )
          .whenComplete(() {
            if (mounted && !widget.isRefreshing) _spinController.reset();
          });
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final sidebarBg = isDark
        ? DynUbuntuTheme.sidebarDark
        : DynUbuntuTheme.sidebarLight;
    final headerBg = isDark
        ? DynUbuntuTheme.headerDark
        : DynUbuntuTheme.headerLight;

    // Settings opens as a standalone full-page view: a single full-width
    // window title bar without the pane-width drag region, back button at
    // the left edge and centred title.
    if (widget.isSettingsOpen) {
      return YaruWindowTitleBar(
        border: BorderSide.none,
        backgroundColor: headerBg,
        platform: YaruWindowControlPlatform.yaru,
        buttonPadding: const EdgeInsets.symmetric(horizontal: 10),
        buttonSpacing: 14,
        leading: _HeaderIconButton(
          icon: const Icon(Icons.arrow_back, size: 18),
          tooltip: l10n.backToSoftware,
          onPressed: widget.onToggleSettings,
        ),
        title: Text(
          l10n.settings,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    return Row(
      children: [
        // Pane-width drag region aligned with the package sidebar.
        SizedBox(
          width: kUbuntuPaneWidth,
          child: YaruWindowTitleBar(
            style: YaruTitleBarStyle.undecorated,
            border: BorderSide.none,
            backgroundColor: sidebarBg,
            // Suppress the fallback window title; this region is the drag
            // area above the sidebar's brand lockup, not a second title.
            title: const SizedBox.shrink(),
          ),
        ),
        SizedBox(
          height: kYaruTitleBarHeight,
          child: VerticalDivider(
            width: 1,
            color: isDark
                ? DynUbuntuTheme.cardBorderDark
                : DynUbuntuTheme.cardBorderLight,
          ),
        ),
        Expanded(
          child: YaruWindowTitleBar(
            border: BorderSide.none,
            backgroundColor: headerBg,
            // Render the Ubuntu/GNOME controls on every platform, so the
            // Windows design preview looks exactly like the Linux app.
            platform: YaruWindowControlPlatform.yaru,
            buttonPadding: const EdgeInsets.symmetric(horizontal: 10),
            buttonSpacing: 14,
            title: Text(
              l10n.productName,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            actions: [
              _HeaderIconButton(
                icon: AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) => Transform.rotate(
                    angle: _spinController.value * 2 * math.pi,
                    child: child,
                  ),
                  child: const Icon(Icons.refresh, size: 18),
                ),
                tooltip: withShortcut(l10n.checkForUpdates, AppShortcuts.refresh),
                onPressed: widget.onRefresh,
              ),
              const SizedBox(width: 4),
              _HeaderIconButton(
                icon: const Icon(Icons.settings, size: 18),
                tooltip: withShortcut(l10n.settings, AppShortcuts.settings),
                onPressed: widget.onToggleSettings,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return YaruIconButton(
      icon: icon,
      onPressed: onPressed,
      iconSize: 18,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}
