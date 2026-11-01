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
  final String? verifyLabel;
  final String uninstallLabel;
  final VoidCallback? onOpenInstallFolder;
  final VoidCallback? onVerifyFiles;
  final VoidCallback? onUninstall;
  final FocusNode? triggerFocus;

  const OverflowMenu({
    super.key,
    required this.triggerLabel,
    required this.uninstallLabel,
    this.openFolderLabel,
    this.verifyLabel,
    this.onOpenInstallFolder,
    this.onVerifyFiles,
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
              MenuFlyoutItem(
                leading: const Icon(
                  FluentIcons.open_folder_horizontal,
                  size: 14,
                ),
                text: Text(state.widget.openFolderLabel!),
                closeAfterClick: false,
                onPressed: state._closeWith(state.widget.onOpenInstallFolder),
              ),
            if (state.widget.verifyLabel != null)
              MenuFlyoutItem(
                leading: const Icon(FluentIcons.verified_brand, size: 14),
                text: Text(state.widget.verifyLabel!),
                closeAfterClick: false,
                onPressed: state._closeWith(state.widget.onVerifyFiles),
              ),
            MenuFlyoutItem(
              leading: Icon(
                FluentIcons.delete,
                size: 14,
                color: tokens.critical,
              ),
              text: Text(
                state.widget.uninstallLabel,
                style: TextStyle(color: tokens.critical),
              ),
              closeAfterClick: false,
              onPressed: state._closeWith(state.widget.onUninstall),
            ),
          ],
        ),
      ),
    );
  }
}
