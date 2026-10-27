import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import 'package:hub_keys/hub_keys.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../errors.dart';
import '../shortcuts.dart';
import '../theme/dynamotivation_theme.dart';

/// Integrated title bar + brand header (82px gradient band, no OS title bar).
class WindowTitleBar extends StatefulWidget {
  final bool isSettingsOpen;
  final VoidCallback onToggleSettings;
  final VoidCallback? onUpdateHub;
  final String? hubUpdateVersion;

  const WindowTitleBar({
    super.key,
    required this.isSettingsOpen,
    required this.onToggleSettings,
    this.onUpdateHub,
    this.hubUpdateVersion,
  });

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.runtimeType.toString().contains("Test")) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (!WidgetsBinding.instance.runtimeType.toString().contains("Test")) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  /// Background probe, not user-initiated: a failure is reported to Flutter's
  /// error handler rather than shown, and the button keeps its last state.
  Future<void> _checkMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = maximized;
        });
      }
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    }
  }

  /// Runs a caption or header action the user asked for. A failure is shown
  /// in an InfoBar.
  Future<void> _runWindowAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final l10n = context.l10n;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: Text(l10n.operationFailed),
          content: Text(describeError(l10n, error)),
          severity: InfoBarSeverity.error,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);

    return Container(
      // Grows with the user's text size so large text is not clipped.
      height:
          82 +
          (MediaQuery.textScalerOf(context).scale(20) - 20).clamp(0.0, 40.0),
      decoration: BoxDecoration(gradient: tokens.headerGradient),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand logo + title. Drag area covers everything not interactive.
                Expanded(
                  child: DragToMoveArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: SvgPicture.asset(
                              'assets/dynamotivation-logo-dark.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.brandName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                context.l10n.productName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.headerForeground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Caption buttons on top, hub actions below.
                Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CaptionButton(
                            icon: _captionMinimizeIcon,
                            tooltip: context.l10n.minimize,
                            onPressed: () =>
                                _runWindowAction(windowManager.minimize),
                          ),
                          _CaptionButton(
                            icon: _isMaximized
                                ? _captionRestoreIcon
                                : _captionMaximizeIcon,
                            tooltip: _isMaximized
                                ? context.l10n.restore
                                : context.l10n.maximize,
                            onPressed: () => _runWindowAction(
                              _isMaximized
                                  ? windowManager.unmaximize
                                  : windowManager.maximize,
                            ),
                          ),
                          _CaptionButton(
                            icon: _captionCloseIcon,
                            tooltip: context.l10n.close,
                            isClose: true,
                            onPressed: () =>
                                _runWindowAction(windowManager.close),
                          ),
                        ],
                      ),
                      // Plain header while in Settings: no hub actions.
                      if (!widget.isSettingsOpen) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _UpdateHubPill(
                                tokens: tokens,
                                hubUpdateVersion: widget.hubUpdateVersion,
                                onUpdateHub: widget.onUpdateHub,
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: withShortcut(
                                  context.l10n.settings,
                                  AppShortcuts.settings,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    FluentIcons.settings,
                                    size: 15,
                                    color: tokens.headerForeground,
                                  ),
                                  onPressed: widget.onToggleSettings,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Signature Dynamotivation mint-to-cyan accent line.
          Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: DynamotivationTheme.brandGradient,
            ),
          ),
        ],
      ),
    );
  }
}

// Windows 11 caption glyphs from Segoe Fluent Icons (the native title bar set).
const _captionMinimizeIcon = IconData(
  0xE921,
  fontFamily: 'Segoe Fluent Icons',
  fontFamilyFallback: ['Segoe MDL2 Assets'],
);
const _captionMaximizeIcon = IconData(
  0xE922,
  fontFamily: 'Segoe Fluent Icons',
  fontFamilyFallback: ['Segoe MDL2 Assets'],
);
const _captionRestoreIcon = IconData(
  0xE923,
  fontFamily: 'Segoe Fluent Icons',
  fontFamilyFallback: ['Segoe MDL2 Assets'],
);
const _captionCloseIcon = IconData(
  0xE8BB,
  fontFamily: 'Segoe Fluent Icons',
  fontFamilyFallback: ['Segoe MDL2 Assets'],
);

class _UpdateHubPill extends StatelessWidget {
  final DynTokens tokens;
  final String? hubUpdateVersion;
  final VoidCallback? onUpdateHub;

  const _UpdateHubPill({
    required this.tokens,
    required this.hubUpdateVersion,
    required this.onUpdateHub,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hubUpdateVersion != null
          ? context.l10n.hubUpdateAvailableTooltip(hubUpdateVersion!)
          : context.l10n.hubUpToDate,
      child: HoverButton(
        onPressed:
            onUpdateHub ??
            () {
              displayInfoBar(
                context,
                builder: (context, close) => InfoBar(
                  title: Text(context.l10n.hubUpdateTitle),
                  content: Text(
                    hubUpdateVersion != null
                        ? context.l10n.hubUpdateReady(hubUpdateVersion!)
                        : context.l10n.hubRunningLatest,
                  ),
                  severity: InfoBarSeverity.info,
                  action: hubUpdateVersion != null
                      ? Button(
                          child: Text(context.l10n.updateNow),
                          onPressed: () {},
                        )
                      : null,
                ),
              );
            },
        builder: (context, states) {
          final isHover = states.isHovered;
          return Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isHover ? tokens.headerHover : tokens.headerPill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DynamotivationTheme.brandGradient,
                  ),
                  child: const Center(
                    child: Icon(
                      FluentIcons.up,
                      size: 9,
                      color: Color(0xFF14241C),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.updateHub,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.headerForeground,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _CaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);

    Color bg = Colors.transparent;
    Color iconColor = tokens.headerForeground;

    if (widget.isClose) {
      if (_isPressed) {
        bg = tokens.captionClosePressed;
        iconColor = Colors.white;
      } else if (_isHovered) {
        bg = tokens.captionCloseHover;
        iconColor = Colors.white;
      }
    } else if (_isPressed) {
      bg = tokens.headerHover.withValues(alpha: 0.35);
    } else if (_isHovered) {
      bg = tokens.headerHover;
    }

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() {
            _isHovered = false;
            _isPressed = false;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 40,
              height: 30,
              color: bg,
              child: Center(
                child: Icon(widget.icon, size: 10, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
