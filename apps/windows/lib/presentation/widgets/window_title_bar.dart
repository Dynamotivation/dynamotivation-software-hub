import 'package:fluent_ui/fluent_ui.dart';
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
                            // Pre-rendered at 192 px and downscaled with
                            // mipmapped filtering: much smoother edges than
                            // rasterising the vector straight to 40 px.
                            child: Image.asset(
                              'assets/dynamotivation-logo-dark-192.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: context.l10n.brandName,
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

                // Caption buttons on top, hub actions below. These are the
                // real Windows 11 caption buttons from window_manager
                // (46x32, system hover/press fills, red close), matching the
                // WindowButtons pattern used by the fluent_ui gallery.
                Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: context.l10n.minimize,
                            child: WindowCaptionButton.minimize(
                              // The band is a dark brand gradient in both
                              // modes, so the dark scheme's white glyphs fit.
                              brightness: Brightness.dark,
                              onPressed: () =>
                                  _runWindowAction(windowManager.minimize),
                            ),
                          ),
                          Tooltip(
                            message: _isMaximized
                                ? context.l10n.restore
                                : context.l10n.maximize,
                            child: _isMaximized
                                ? WindowCaptionButton.unmaximize(
                                    brightness: Brightness.dark,
                                    onPressed: () => _runWindowAction(
                                      windowManager.unmaximize,
                                    ),
                                  )
                                : WindowCaptionButton.maximize(
                                    brightness: Brightness.dark,
                                    onPressed: () => _runWindowAction(
                                      windowManager.maximize,
                                    ),
                                  ),
                          ),
                          Tooltip(
                            message: context.l10n.close,
                            child: WindowCaptionButton.close(
                              brightness: Brightness.dark,
                              onPressed: () =>
                                  _runWindowAction(windowManager.close),
                            ),
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
