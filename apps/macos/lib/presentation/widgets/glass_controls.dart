import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:hub_keys/hub_keys.dart';
import 'package:macos_ui/macos_ui.dart';

import '../theme/dynamotivation_macos_theme.dart';

/// Capsule that imitates the Tahoe toolbar glass: a blurred, translucent,
/// softly lit pill that floats above content. Flutter cannot render the real
/// system Liquid Glass, so this is an approximation for the navigation layer
/// only; it is never used for content.
class GlassGroup extends StatelessWidget {
  final List<Widget> children;

  /// True when sitting on the brand gradient (white glass), false on a plain
  /// surface (tinted glass).
  final bool onGradient;

  const GlassGroup({super.key, required this.children, this.onGradient = true});

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness.isDark;
    // Windows high-contrast mode: no translucency or blur, solid fill and a
    // strong border so the controls stay distinguishable.
    if (MediaQuery.highContrastOf(context)) {
      final fg = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: fg, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );
    }
    final fill = onGradient
        ? const Color(0x33FFFFFF)
        : (isDark ? const Color(0x24FFFFFF) : const Color(0x0F000000));
    final border = onGradient
        ? const Color(0x59FFFFFF)
        : (isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon button inside a [GlassGroup]. Keyboard focusable (Tab, Enter/Space)
/// with a visible focus ring, a tooltip and a screen-reader label.
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool onGradient;

  /// Shown in the tooltip, named after the user's keyboard layout
  /// (Strg/Ctrl/⌘).
  final SingleActivator? shortcut;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.onGradient = true,
    this.shortcut,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.of(context).brightness.isDark;
    final enabled = widget.onPressed != null;
    final color = widget.onGradient
        ? const Color(0xFFFFFFFF)
        : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000));
    final hover = widget.onGradient
        ? const Color(0x33FFFFFF)
        : (isDark ? const Color(0x24FFFFFF) : const Color(0x14000000));
    final highContrast = MediaQuery.highContrastOf(context);
    final ringColor = highContrast
        ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
        : color;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: MacosTooltip(
        message: widget.shortcut == null
            ? widget.label
            : withShortcut(widget.label, widget.shortcut!),
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          onShowFocusHighlight: (v) => setState(() => _focus = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _hover && enabled ? hover : const Color(0x00000000),
                borderRadius: BorderRadius.circular(100),
                // Visible keyboard focus ring (>= 3:1 against the glass).
                border: Border.all(
                  color: _focus ? ringColor : const Color(0x00000000),
                  width: 2,
                ),
              ),
              child: SizedBox(
                width: 34,
                height: 30,
                child: Center(
                  child: MacosIcon(
                    widget.icon,
                    size: 16,
                    color: enabled ? color : color.withValues(alpha: 0.4),
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

/// One entry of a [MoreMenuButton].
class MoreMenuEntry {
  final String label;
  final VoidCallback onSelected;

  const MoreMenuEntry({required this.label, required this.onSelected});
}

/// Borderless "more" button (vertical ellipsis, no chevron) that opens a small
/// menu anchored below its right edge. Keyboard focusable, labelled for
/// screen readers; the first entry is focused when the menu opens.
class MoreMenuButton extends StatelessWidget {
  final String label;
  final List<MoreMenuEntry> entries;

  /// True on the brand gradient (white icon), false on a plain surface.
  final bool onGradient;

  const MoreMenuButton({
    super.key,
    required this.label,
    required this.entries,
    this.onGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => GlassIconButton(
        icon: CupertinoIcons.ellipsis_vertical,
        label: label,
        onGradient: onGradient,
        onPressed: () => _open(buttonContext),
      ),
    );
  }

  void _open(BuildContext buttonContext) {
    final box = buttonContext.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(buttonContext);
    final theme = MacosTheme.of(buttonContext);
    final isDark = theme.brightness.isDark;

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: label,
      barrierColor: const Color(0x00000000),
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, _) => Stack(
        children: [
          Positioned(
            top: origin.dy + box.size.height + 4,
            right: screen.width - (origin.dx + box.size.width),
            child: MacosTheme(
              data: theme,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0x33FFFFFF)
                        : const Color(0x26000000),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          _MenuRow(
                            entry: entries[i],
                            autofocus: i == 0,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              entries[i].onSelected();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  final MoreMenuEntry entry;
  final bool autofocus;
  final VoidCallback onTap;

  const _MenuRow({
    required this.entry,
    required this.autofocus,
    required this.onTap,
  });

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Semantics(
      button: true,
      label: widget.entry.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        autofocus: widget.autofocus,
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _active = v),
        onShowFocusHighlight: (v) => setState(() => _active = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              // Highlighted row: solid brand colour, white text (>= 4.5:1).
              color: _active ? DynBrand.accent : const Color(0x00000000),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.entry.label,
              style: theme.typography.body.copyWith(
                color: _active ? const Color(0xFFFFFFFF) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
