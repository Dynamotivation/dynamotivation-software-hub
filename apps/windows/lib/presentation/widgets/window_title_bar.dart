import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

import 'package:hub_keys/hub_keys.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../errors.dart';
import '../shortcuts.dart';
import '../theme/dynamotivation_theme.dart';
import 'accessible_icon_button.dart';

/// Integrated title bar + brand header (82px gradient band, no OS title bar).
class WindowTitleBar extends StatefulWidget {
  final bool isSettingsOpen;
  final FocusNode? settingsFocusNode;
  final VoidCallback onToggleSettings;
  final VoidCallback? onUpdateHub;
  final String? hubUpdateVersion;

  const WindowTitleBar({
    super.key,
    required this.isSettingsOpen,
    this.settingsFocusNode,
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
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
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
      await showDialog<void>(
        context: context,
        builder: (context) => ContentDialog(
          title: Text(l10n.operationFailed),
          content: Text(describeError(l10n, error)),
          actions: [
            Button(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
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
      // Let the actual localized/scaled text determine the header's height.
      constraints: const BoxConstraints(minHeight: 82),
      decoration: BoxDecoration(gradient: tokens.headerGradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                          // Pre-rendered at 192 px and downscaled with
                          // mipmapped filtering: much smoother edges than
                          // rasterising the vector straight to 40 px.
                          child: Image.asset(
                            'assets/dynamotivation-logo-dark-192.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.brandName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.headerForeground,
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Native window commands with keyboard-operable caption buttons.
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
                          label: context.l10n.minimize,
                          icon: FluentIcons.chrome_minimize,
                          onPressed: () =>
                              _runWindowAction(windowManager.minimize),
                        ),
                        _CaptionButton(
                          label: _isMaximized
                              ? context.l10n.restore
                              : context.l10n.maximize,
                          icon: _isMaximized
                              ? FluentIcons.chrome_restore
                              : FluentIcons.square_shape,
                          onPressed: () => _runWindowAction(
                            _isMaximized
                                ? windowManager.unmaximize
                                : windowManager.maximize,
                          ),
                        ),
                        _CaptionButton(
                          label: context.l10n.close,
                          icon: FluentIcons.chrome_close,
                          close: true,
                          onPressed: () =>
                              _runWindowAction(windowManager.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _UpdateHubPill(
                            iconOnly: MediaQuery.sizeOf(context).width < 800,
                            tokens: tokens,
                            hubUpdateVersion: widget.hubUpdateVersion,
                            onUpdateHub: widget.onUpdateHub,
                          ),
                          const SizedBox(width: 6),
                          AccessibleIconButton(
                            label: context.l10n.settings,
                            tooltip: withShortcut(
                              context.l10n.settings,
                              AppShortcuts.settings,
                            ),
                            icon: Icon(
                              FluentIcons.settings,
                              size: 15,
                              color: tokens.headerForeground,
                            ),
                            focusNode: widget.settingsFocusNode,
                            onPressed: widget.onToggleSettings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Signature Dynamotivation mint-to-cyan accent line.
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: MediaQuery.highContrastOf(context)
                  ? tokens.headerForeground
                  : null,
              gradient: MediaQuery.highContrastOf(context)
                  ? null
                  : DynamotivationTheme.brandGradient,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateHubPill extends StatelessWidget {
  final DynTokens tokens;
  final bool iconOnly;
  final String? hubUpdateVersion;
  final VoidCallback? onUpdateHub;

  const _UpdateHubPill({
    required this.tokens,
    this.iconOnly = false,
    required this.hubUpdateVersion,
    required this.onUpdateHub,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hubUpdateVersion != null
          ? context.l10n.hubUpdateAvailableTooltip(hubUpdateVersion!)
          : context.l10n.hubUpToDate,
      child: Semantics(
        container: true,
        button: true,
        label: context.l10n.updateHub,
        child: HoverButton(
          semanticLabel: context.l10n.updateHub,
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
            return FocusBorder(
              focused: states.isFocused,
              child: Container(
                constraints: const BoxConstraints(minHeight: 28),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MediaQuery.highContrastOf(context)
                            ? tokens.window
                            : null,
                        gradient: MediaQuery.highContrastOf(context)
                            ? null
                            : DynamotivationTheme.brandGradient,
                      ),
                      child: Center(
                        child: Icon(
                          FluentIcons.up,
                          size: 9,
                          color: MediaQuery.highContrastOf(context)
                              ? tokens.text
                              : const Color(0xFF14241C),
                        ),
                      ),
                    ),
                    if (!iconOnly) ...[
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The window_manager caption widgets are pointer-only. Keep native commands,
/// standard caption dimensions, and add the same keyboard/semantics support as
/// other Fluent controls.
class _CaptionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool close;
  const _CaptionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.close = false,
  });

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  late final FocusNode _focus = FocusNode()..addListener(_changed);

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);
    final contrast = MediaQuery.highContrastOf(context);
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: true,
      focusable: true,
      focused: _focus.hasFocus,
      label: widget.label,
      onTap: widget.onPressed,
      onFocus: _focus.requestFocus,
      child: Tooltip(
        message: widget.label,
        child: HoverButton(
          focusNode: _focus,
          onPressed: widget.onPressed,
          semanticLabel: widget.label,
          builder: (context, states) => FocusBorder(
            focused: states.isFocused,
            child: Container(
              width: 46,
              height: 32,
              decoration: BoxDecoration(
                color: states.isHovered || states.isPressed
                    ? (widget.close && !contrast
                          ? DynamotivationTheme.captionCloseHover
                          : tokens.headerHover)
                    : Colors.transparent,
                border: contrast && states.isHovered
                    ? Border.all(color: tokens.text)
                    : null,
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 12,
                  color: tokens.headerForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
