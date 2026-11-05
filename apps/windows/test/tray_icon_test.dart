import 'package:dynamotivation_software_hub/background/background_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a dark taskbar gets the dark-taskbar icon, a light one the light icon', () {
    expect(
      trayIconAssetFor(taskbarLight: false),
      'assets/tray_icon_dark.ico',
    );
    expect(trayIconAssetFor(taskbarLight: true), 'assets/tray_icon.ico');
  });

  test('until the taskbar theme is read the light icon is used', () {
    expect(trayIconAssetFor(taskbarLight: null), 'assets/tray_icon.ico');
  });
}
