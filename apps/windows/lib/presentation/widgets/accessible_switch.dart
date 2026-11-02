import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../theme/dynamotivation_theme.dart';

/// A switch that is a single semantics node: name, description, state
/// (toggled), enabled state, and the activation action all live on the same
/// node, so screen readers announce one complete control.
///
/// The track follows the Windows 11 toggle. Brand styling is dropped under
/// high contrast: the tokens resolve to the system palette there.
class AccessibleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? description;
  final FocusNode? focusNode;

  const AccessibleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
    this.focusNode,
  });

  @override
  State<AccessibleSwitch> createState() => _AccessibleSwitchState();
}

class _AccessibleSwitchState extends State<AccessibleSwitch> {
  late FocusNode _focus;
  bool _visibleFocus = false;
  void _focusChanged() {
    setState(() {});
    if (_focus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focus.hasFocus) {
          Scrollable.ensureVisible(context, alignment: 0.5);
        }
      });
    }
  }

  bool get _enabled => widget.onChanged != null;

  void _toggle() {
    if (_enabled) widget.onChanged?.call(!widget.value);
  }

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode(debugLabel: widget.label);
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(AccessibleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focus.removeListener(_focusChanged);
      if (oldWidget.focusNode == null) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode(debugLabel: widget.label);
      _focus.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    // An externally owned node is not ours to dispose.
    _focus.removeListener(_focusChanged);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final collapsed = MediaQuery.disableAnimationsOf(context);

    final disabled = !_enabled;
    // Track: the brand accent when on. Under high contrast the brand styling
    // is dropped and the Fluent disabled resources resolve to the system
    // palette colors.
    final wavelength = FluentTheme.of(context).resources;
    final Color disabledFill = wavelength.textFillColorDisabled;
    final Color trackOn = highContrast ? tokens.text : tokens.brandAccent;
    final Color trackOff = tokens.cardBorder;
    final Color trackDisabled = disabledFill;
    final Color knobColor = highContrast ? tokens.window : tokens.card;

    return Semantics(
      container: true,
      excludeSemantics: true,
      enabled: _enabled,
      focusable: _enabled,
      focused: _focus.hasFocus,
      label: widget.label,
      hint: widget.description,
      toggled: widget.value,
      onTap: _enabled ? _toggle : null,
      onFocus: _enabled
          ? () {
              _focus.requestFocus();
            }
          : null,
      child: CallbackShortcuts(
        bindings: {SingleActivator(LogicalKeyboardKey.space): _toggle},
        child: FocusableActionDetector(
          focusNode: _focus,
          autofocus: false,
          enabled: _enabled,
          mouseCursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (visible) =>
              setState(() => _visibleFocus = visible),
          onFocusChange: (_) => setState(() {}),
          actions: {
            ActivateAction: CallbackAction<ActivateIntent>(
              onInvoke: (_) => _toggle(),
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _enabled ? _toggle : null,
            child: FocusBorder(
              focused: _visibleFocus || _focus.hasFocus,
              child: Container(
                // 44x24 logical px track; the 24px height also satisfies the
                // project minimum target size.
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: disabled
                      ? trackDisabled
                      : (widget.value
                            ? trackOn
                            : (highContrast ? (tokens.text) : trackOff)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: disabled && !highContrast
                        ? tokens.divider
                        : tokens.text,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AnimatedAlign(
                    duration: collapsed
                        ? Duration.zero
                        : const Duration(milliseconds: 100),
                    curve: collapsed ? Curves.linear : Curves.easeOutCubic,
                    alignment: widget.value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: knobColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
