import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:hub_keys/hub_keys.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../theme/dynamotivation_theme.dart';

/// Fixed footprint: a running app splits the same button into two equal parts.
class RunActionButton extends StatefulWidget {
  final String name;
  final bool running;
  final bool busy;
  final bool enabled;
  final bool primary;
  final FocusNode? focusNode;
  final ValueChanged<bool> onLaunch;
  final VoidCallback onForceClose;

  const RunActionButton({
    super.key,
    required this.name,
    required this.running,
    required this.busy,
    required this.enabled,
    required this.primary,
    this.focusNode,
    required this.onLaunch,
    required this.onForceClose,
  });

  @override
  State<RunActionButton> createState() => _RunActionButtonState();
}

class _RunActionButtonState extends State<RunActionButton> {
  late final FocusNode _ownedFocus = FocusNode(
    debugLabel: 'Launch application',
  );
  final _closeFocus = FocusNode(debugLabel: 'Force close application');
  FocusNode get _launchFocus => widget.focusNode ?? _ownedFocus;
  bool get _control => HardwareKeyboard.instance.isControlPressed;
  bool _confirming = false;
  bool _returnFocusToLaunch = false;

  bool _keyChanged(KeyEvent event) {
    if (mounted) setState(() {});
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_keyChanged);
    _closeFocus.addListener(_focusChanged);
    _launchFocus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(RunActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running &&
        !widget.running &&
        (_closeFocus.hasFocus || _returnFocusToLaunch)) {
      _returnFocusToLaunch = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _launchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyChanged);
    _launchFocus.removeListener(_focusChanged);
    _closeFocus.removeListener(_focusChanged);
    _ownedFocus.dispose();
    _closeFocus.dispose();
    super.dispose();
  }

  Future<void> _confirmClose() async {
    if (_confirming || widget.busy) return;
    _confirming = true;
    final l10n = context.l10n;
    final close = widget.onForceClose;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.forceCloseTitle(widget.name)),
        content: Text(l10n.forceCloseBody(widget.name)),
        actions: [
          Button(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.noAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yesAction),
          ),
        ],
      ),
    );
    _confirming = false;
    if (!mounted) return;
    if (widget.running) {
      _closeFocus.requestFocus();
    } else {
      _launchFocus.requestFocus();
    }
    if (yes == true) {
      _returnFocusToLaunch = true;
      close();
    }
  }

  ButtonStyle _style(bool primary, bool grey, bool close) {
    final theme = FluentTheme.of(context);
    final base = primary
        ? theme.buttonTheme.filledButtonStyle
        : DynamotivationTheme.secondaryActionStyle(context);
    return (base ?? const ButtonStyle()).merge(
      ButtonStyle(
        shape: widget.running
            ? WidgetStateProperty.resolveWith((states) {
                final shape =
                    base?.shape?.resolve(states) ??
                    (primary
                        ? FilledButton.shapeBorder(theme, states)
                        : ButtonThemeData.shapeBorder(context, states));
                final rounded = switch (shape) {
                  RoundedRectangleBorder(:final borderRadius) => borderRadius,
                  RoundedRectangleGradientBorder(:final borderRadius) =>
                    borderRadius,
                  _ => BorderRadius.zero,
                };
                final radius = rounded.resolve(Directionality.of(context));
                final segment = BorderRadius.only(
                  topLeft: close ? Radius.zero : radius.topLeft,
                  bottomLeft: close ? Radius.zero : radius.bottomLeft,
                  topRight: close ? radius.topRight : Radius.zero,
                  bottomRight: close ? radius.bottomRight : Radius.zero,
                );
                return switch (shape) {
                  RoundedRectangleBorder border => border.copyWith(
                    borderRadius: segment,
                  ),
                  RoundedRectangleGradientBorder border =>
                    RoundedRectangleGradientBorder(
                      gradient: border.gradient,
                      borderRadius: segment,
                      width: border.width,
                      strokeAlign: border.strokeAlign,
                      style: border.style,
                    ),
                  _ => shape,
                };
              })
            : null,
        backgroundColor: grey
            ? WidgetStatePropertyAll(theme.resources.controlFillColorDisabled)
            : null,
        foregroundColor: grey
            ? WidgetStatePropertyAll(DynTokens.of(context).textMuted)
            : null,
      ),
    )!;
  }

  Widget _part({required bool close}) {
    final l10n = context.l10n;
    final label = close
        ? l10n.forceClose
        : widget.running
        ? l10n.launchAnotherInstance
        : l10n.launch;
    final focus = close ? _closeFocus : _launchFocus;
    final enabled = widget.enabled && !widget.busy;
    final hint = widget.running
        ? '${l10n.modifierClickHint(controlClickLabel(l10n.clickAction), label)}\n${withShortcut(label, const SingleActivator(LogicalKeyboardKey.enter, control: true))}'
        : label;
    void activate() {
      if (close) {
        _confirmClose();
      } else {
        widget.onLaunch(widget.running);
      }
    }

    final style = _style(
      widget.primary && !close,
      widget.running && !_control,
      close,
    );
    final child = close
        ? const Icon(FluentIcons.chrome_close, size: 16)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.play, size: 13),
              const SizedBox(width: 8),
              Flexible(
                child: Text(widget.running ? l10n.running : l10n.launch),
              ),
            ],
          );
    final onPressed = !enabled
        ? null
        : () {
            if (!widget.running || _control) activate();
          };
    final button = widget.primary && !close
        ? FilledButton(
            focusNode: focus,
            style: style,
            onPressed: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: child,
            ),
          )
        : Button(
            focusNode: focus,
            style: style,
            onPressed: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: child,
            ),
          );
    return Semantics(
      container: true,
      liveRegion: !close,
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      value: widget.running ? l10n.running : null,
      focusable: enabled,
      focused: focus.hasFocus,
      onFocus: enabled ? focus.requestFocus : null,
      // Assistive activation is an equivalent to the modifier gesture.
      onTap: enabled ? activate : null,
      excludeSemantics: true,
      child: Tooltip(
        message: hint,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
              if (enabled) activate();
            },
            const SingleActivator(LogicalKeyboardKey.space, control: true): () {
              if (enabled) activate();
            },
          },
          child: button,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('run-action-footprint'),
    width: 240,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _part(close: false)),
          if (widget.running) Expanded(child: _part(close: true)),
        ],
      ),
    ),
  );
}
