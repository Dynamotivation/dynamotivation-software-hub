import 'package:fluent_ui/fluent_ui.dart';

import 'click_cursor.dart';

/// A distinct, named semantic button even inside controls that merge semantics.
/// Keyboard focus and screen-reader focus refer to the same owned focus node.
class AccessibleIconButton extends StatefulWidget {
  final String label;
  final String? tooltip;
  final Widget icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  const AccessibleIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.focusNode,
  });

  @override
  State<AccessibleIconButton> createState() => _AccessibleIconButtonState();
}

class _AccessibleIconButtonState extends State<AccessibleIconButton> {
  late FocusNode _focus;
  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode(debugLabel: widget.label);
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(AccessibleIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focus.removeListener(_changed);
      if (oldWidget.focusNode == null) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode(debugLabel: widget.label);
      _focus.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _activate() {
    _focus.requestFocus();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    enabled: widget.onPressed != null,
    label: widget.label,
    focusable: widget.onPressed != null,
    focused: _focus.hasFocus,
    onTap: widget.onPressed != null ? _activate : null,
    onFocus: widget.onPressed != null ? _focus.requestFocus : null,
    excludeSemantics: true,
    child: Tooltip(
      message: widget.tooltip ?? widget.label,
      child: ClickIconButton(
        focusNode: _focus,
        icon: widget.icon,
        onPressed: widget.onPressed != null ? _activate : null,
      ),
    ),
  );
}
