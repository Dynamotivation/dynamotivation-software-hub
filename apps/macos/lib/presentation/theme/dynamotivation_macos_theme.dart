import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:macos_ui/macos_ui.dart';

/// Dynamotivation brand tokens, applied on top of the macOS HIG look
/// (system fonts, translucent sidebar, push buttons, sheets). Values match
/// the Windows frontend's `DynTokens`.
abstract final class DynBrand {
  static const accent = Color(0xFFE22050);
  static const accentDark = Color(0xFFC91A45);
  static const maroon = Color(0xFF893750);

  static const canvasLight = Color(0xFFF5F2F5);
  static const canvasDark = Color(0xFF1E1A1D);
  static const sidebarLight = Color(0xFFEAE4E8);
  static const sidebarDark = Color(0xFF2A2428);

  /// The 135deg header gradient.
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4C4A), Color(0xFF893750)],
  );

  /// Header gradient with a 20% black scrim so white text keeps >= 4.5:1
  /// (plain [gradient] start is only 3.3:1 against white).
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCC3C3B), Color(0xFF893750)],
  );

  static MacosThemeData light() => MacosThemeData(
    brightness: Brightness.light,
    primaryColor: accent,
    accentColor: AccentColor.pink,
  );

  static MacosThemeData dark() => MacosThemeData(
    brightness: Brightness.dark,
    primaryColor: accent,
    accentColor: AccentColor.pink,
  );
}
