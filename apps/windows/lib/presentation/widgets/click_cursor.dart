import 'package:fluent_ui/fluent_ui.dart';

/// Shows the hand cursor over [child] while it is [enabled]. Fluent's own
/// controls defer to the default arrow, so every clickable control of the app
/// is wrapped in this (or built from the `Click*` wrappers below).
class ClickCursor extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const ClickCursor({super.key, this.enabled = true, required this.child});

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
    child: child,
  );
}

/// [Button] with the hand cursor while it can be pressed.
class ClickButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final ButtonStyle? style;
  final Widget child;
  const ClickButton({
    super.key,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ClickCursor(
    enabled: onPressed != null,
    child: Button(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      child: child,
    ),
  );
}

/// [FilledButton] with the hand cursor while it can be pressed.
class ClickFilledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final ButtonStyle? style;
  final Widget child;
  const ClickFilledButton({
    super.key,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ClickCursor(
    enabled: onPressed != null,
    child: FilledButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      child: child,
    ),
  );
}

/// [IconButton] with the hand cursor while it can be pressed.
class ClickIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  const ClickIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) => ClickCursor(
    enabled: onPressed != null,
    child: IconButton(icon: icon, onPressed: onPressed, focusNode: focusNode),
  );
}
