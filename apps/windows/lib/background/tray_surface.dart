import 'package:system_tray/system_tray.dart';

/// The Windows system tray icon, the visible handle to the background
/// surface. There is no disabled state to model: when the background
/// surface is off, the icon does not exist.
class TraySurface {
  TraySurface({required this.onOpenHub, required this.onEnd});

  final void Function() onOpenHub;
  final void Function() onEnd;

  final SystemTray _tray = SystemTray();
  bool _installed = false;

  /// Installs the icon with its context menu. Calls that arrive while the
  /// icon already exists are no-ops, so settings changes can restate the
  /// request freely.
  Future<void> install({
    required String iconAsset,
    required String tooltip,
    required String openLabel,
    required String endLabel,
  }) async {
    if (_installed) return;
    _installed = true;

    await _tray.initSystemTray(iconPath: iconAsset, toolTip: tooltip);
    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: openLabel, onClicked: (_) => onOpenHub()),
      MenuItemLabel(label: endLabel, onClicked: (_) => onEnd()),
    ]);
    await _tray.setContextMenu(menu);
    _tray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        onOpenHub();
      } else if (eventName == kSystemTrayEventRightClick) {
        _tray.popUpContextMenu();
      }
    });
  }

  /// Swaps the icon image, e.g. when the taskbar changes between light and
  /// dark. Does nothing while the icon is not installed.
  Future<void> setIcon(String iconAsset) async {
    if (!_installed) return;
    await _tray.setImage(iconAsset);
  }

  /// Removes the icon. Like [install], idempotent.
  Future<void> remove() async {
    if (!_installed) return;
    _installed = false;
    await _tray.destroy();
  }
}
