import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../theme/dynamotivation_theme.dart';
import 'accessible_icon_button.dart';

/// The package overflow menu ("More options").
///
/// It is a managed [FlyoutController] flyout, not a [DropDownButton], so the
/// app owns its close semantics: the chosen action is returned through the
/// flyout's close result, so the menu is closed before any dialog it opens is
/// pushed — a cancel there can never leave a stale menu with focus trapped
/// behind it. When the menu closes without opening something else, focus
/// returns to the trigger button.
///
/// Arrow navigation, Enter activation and Escape dismissal are the standard
/// [MenuFlyout] behaviors; the trigger keeps its owned focus node.
class OverflowMenu extends StatefulWidget {
  final String triggerLabel;
  final String? openFolderLabel;

  /// Shown only when not null.
  final String? installVersionLabel;

  /// Shown only when not null.
  final String? uninstallLabel;
  final VoidCallback? onOpenInstallFolder;
  final VoidCallback? onInstallVersion;
  final VoidCallback? onUninstall;
  final FocusNode? triggerFocus;

  const OverflowMenu({
    super.key,
    required this.triggerLabel,
    this.installVersionLabel,
    this.uninstallLabel,
    this.openFolderLabel,
    this.onOpenInstallFolder,
    this.onInstallVersion,
    this.onUninstall,
    this.triggerFocus,
  });

  @override
  State<OverflowMenu> createState() => _OverflowMenuState();
}

class _OverflowMenuState extends State<OverflowMenu> {
  final _controller = FlyoutController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_controller.isOpen) {
      _controller.close();
      return;
    }
    final action = await _controller.showFlyout<VoidCallback?>(
      barrierColor: Colors.transparent,
      placementMode: FlyoutPlacementMode.bottomRight,
      dismissWithEsc: true,
      builder: (context) => _MenuSurface(state: this),
    );
    if (!mounted) return;
    // The menu is gone; put focus back on the trigger either way, so a
    // cancelled dialog or a simple dismissal resumes the keyboard journey.
    final node = widget.triggerFocus;
    if (node != null && node.context != null && node.canRequestFocus) {
      node.requestFocus();
    }
    action?.call();
  }

  VoidCallback? _closeWith(VoidCallback? action) =>
      action == null ? null : () => _controller.close(action);

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _controller,
      child: AccessibleIconButton(
        label: widget.triggerLabel,
        icon: const Icon(FluentIcons.more_vertical, size: 16),
        focusNode: widget.triggerFocus,
        onPressed: _open,
      ),
    );
  }
}

class _MenuSurface extends StatelessWidget {
  final _OverflowMenuState state;

  const _MenuSurface({required this.state});

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.escape): () =>
            state._controller.close(),
      },
      child: FocusTraversalGroup(
        child: MenuFlyout(
          items: [
            if (state.widget.openFolderLabel != null)
              MenuFlyoutItemBuilder(
                builder: (context) => _AccessibleMenuItem(
                  leading: const Icon(
                    FluentIcons.open_folder_horizontal,
                    size: 14,
                  ),
                  label: state.widget.openFolderLabel!,
                  onPressed: state._closeWith(state.widget.onOpenInstallFolder),
                ),
              ),
            if (state.widget.installVersionLabel != null)
              MenuFlyoutItemBuilder(
                builder: (context) => _AccessibleMenuItem(
                  leading: const Icon(FluentIcons.history, size: 14),
                  label: state.widget.installVersionLabel!,
                  onPressed: state._closeWith(state.widget.onInstallVersion),
                ),
              ),
            if (state.widget.uninstallLabel != null)
              MenuFlyoutItemBuilder(
                builder: (context) => _AccessibleMenuItem(
                  leading: Icon(
                    FluentIcons.delete,
                    size: 14,
                    color: tokens.critical,
                  ),
                  label: state.widget.uninstallLabel!,
                  textStyle: TextStyle(color: tokens.critical),
                  onPressed: state._closeWith(state.widget.onUninstall),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fluent's menu tile exposes only its text on Windows. Keep its keyboard and
/// visual behavior, while giving the native bridge an actionable named node.
class _AccessibleMenuItem extends StatefulWidget {
  const _AccessibleMenuItem({
    required this.label,
    required this.leading,
    required this.onPressed,
    this.textStyle,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;

  @override
  State<_AccessibleMenuItem> createState() => _AccessibleMenuItemState();
}

class _AccessibleMenuItemState extends State<_AccessibleMenuItem> {
  late final FocusNode _focus = FocusNode()..addListener(_changed);
  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    excludeSemantics: true,
    button: true,
    enabled: widget.onPressed != null,
    focusable: widget.onPressed != null,
    focused: _focus.hasFocus,
    label: widget.label,
    onTap: widget.onPressed,
    onFocus: widget.onPressed == null ? null : _focus.requestFocus,
    child: MenuFlyoutItem(
      leading: widget.leading,
      text: Text(widget.label, style: widget.textStyle),
      focusNode: _focus,
      closeAfterClick: false,
      onPressed: widget.onPressed,
    ).build(context),
  );
}
