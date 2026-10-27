import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hub_keys/hub_keys.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:window_manager/window_manager.dart';

import '../shortcuts.dart';
import '../theme/dynamotivation_ubuntu_theme.dart';

/// Ubuntu GNOME-style HeaderBar with integrated drag region, title, actions,
/// and native Ubuntu Yaru window controls.
/// Follows single-logo rule (no duplicate logo in header bar; brand lockup stays in sidebar).
class UbuntuHeaderBar extends StatefulWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(48);

  @override
  State<UbuntuHeaderBar> createState() => _UbuntuHeaderBarState();
}

class _UbuntuHeaderBarState extends State<UbuntuHeaderBar>
    with WindowListener, SingleTickerProviderStateMixin {
  bool _isMaximized = false;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      windowManager.addListener(this);
      _checkMaximized();
    }
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
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = maximized);
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _toggleMaximize() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final headerBg = isDark
        ? DynUbuntuTheme.headerDark
        : DynUbuntuTheme.headerLight;
    final borderColor = isDark
        ? DynUbuntuTheme.cardBorderDark
        : DynUbuntuTheme.cardBorderLight;

    return Container(
      height: 48 + (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0.0, 20.0),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Title or Back Button
          Expanded(
            child: GestureDetector(
              onDoubleTap: _toggleMaximize,
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Row(
                    children: [
                      if (widget.isSettingsOpen) ...[
                        _HeaderIconButton(
                          icon: const Icon(Icons.arrow_back, size: 18),
                          tooltip: l10n.backToSoftware,
                          onPressed: widget.onToggleSettings,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.settings,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else ...[
                        Flexible(
                          child: Text(
                            l10n.productName,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Center/Right: Actions (when not in settings)
          if (!widget.isSettingsOpen)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Refresh button with animation
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

                // Settings button
                _HeaderIconButton(
                  icon: const Icon(Icons.settings, size: 18),
                  tooltip: withShortcut(l10n.settings, AppShortcuts.settings),
                  onPressed: widget.onToggleSettings,
                ),

                const SizedBox(width: 8),
                VerticalDivider(
                  indent: 12,
                  endIndent: 12,
                  width: 1,
                  color: borderColor,
                ),
                const SizedBox(width: 8),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                VerticalDivider(
                  indent: 12,
                  endIndent: 12,
                  width: 1,
                  color: borderColor,
                ),
                const SizedBox(width: 8),
              ],
            ),

          // Rightmost: Ubuntu Window Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UbuntuWindowButton(
                type: _WindowButtonType.minimize,
                onPressed: () => windowManager.minimize(),
              ),
              const SizedBox(width: 6),
              _UbuntuWindowButton(
                type: _isMaximized
                    ? _WindowButtonType.restore
                    : _WindowButtonType.maximize,
                onPressed: _toggleMaximize,
              ),
              const SizedBox(width: 6),
              _UbuntuWindowButton(
                type: _WindowButtonType.close,
                onPressed: () => windowManager.close(),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}

enum _WindowButtonType { close, minimize, maximize, restore }

class _UbuntuWindowButton extends StatefulWidget {
  final _WindowButtonType type;
  final VoidCallback onPressed;

  const _UbuntuWindowButton({
    required this.type,
    required this.onPressed,
  });

  @override
  State<_UbuntuWindowButton> createState() => _UbuntuWindowButtonState();
}

class _UbuntuWindowButtonState extends State<_UbuntuWindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClose = widget.type == _WindowButtonType.close;

    Color bg;
    Color fg;

    if (isClose) {
      if (_hovered) {
        bg = DynUbuntuTheme.ubuntuOrange;
        fg = Colors.white;
      } else {
        bg = isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000);
        fg = isDark ? Colors.white70 : Colors.black87;
      }
    } else {
      if (_hovered) {
        bg = isDark ? const Color(0x44FFFFFF) : const Color(0x33000000);
        fg = isDark ? Colors.white : Colors.black;
      } else {
        bg = isDark ? const Color(0x22FFFFFF) : const Color(0x14000000);
        fg = isDark ? Colors.white60 : Colors.black54;
      }
    }

    IconData icon;
    switch (widget.type) {
      case _WindowButtonType.close:
        icon = Icons.close;
        break;
      case _WindowButtonType.minimize:
        icon = Icons.remove;
        break;
      case _WindowButtonType.maximize:
        icon = Icons.crop_square;
        break;
      case _WindowButtonType.restore:
        icon = Icons.filter_none;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 12, color: fg),
        ),
      ),
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
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        splashRadius: 18,
        iconSize: 18,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
