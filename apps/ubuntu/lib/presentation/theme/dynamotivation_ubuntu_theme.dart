import 'package:flutter/material.dart';

/// Dynamotivation tokens fused with Ubuntu Yaru styling.
///
/// Fuses Ubuntu's canonical design system (Yaru, Ubuntu Orange, Aubergine,
/// and GNOME desktop conventions) with Dynamotivation's crimson/coral brand identity.
abstract final class DynUbuntuTheme {
  // Canonical Ubuntu colors
  static const ubuntuOrange = Color(0xFFE95420);
  static const ubuntuAubergine = Color(0xFF77216F);
  static const ubuntuAubergineDark = Color(0xFF5E2750);
  static const ubuntuAubergineDeep = Color(0xFF2C001E);
  static const ubuntuWarmGrey = Color(0xFFAEA79F);
  static const ubuntuCoolGrey = Color(0xFF333333);

  // Dynamotivation brand colors
  static const crimson = Color(0xFFCC3C3B);
  static const coralAccent = Color(0xFFE22050);
  static const coralDark = Color(0xFFC91A45);
  static const coralDarker = Color(0xFFB0163C);
  static const maroon = Color(0xFF893750);

  // Mint & Cyan signature accents
  static const mintAccent = Color(0xFF4AFF83);
  static const cyanAccent = Color(0xFF3DFFE5);

  // Fused Header Gradient: Ubuntu Aubergine into Dynamotivation Coral/Maroon
  static const fusedHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5E2750), Color(0xFF893750)],
  );

  static const fusedBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ubuntuOrange, coralAccent],
  );

  // Dark and Light header backgrounds for Ubuntu GNOME HeaderBar
  static const headerDark = Color(0xFF2B262A);
  static const headerLight = Color(0xFFEDE8EC);

  // Sidebar surfaces
  static const sidebarDark = Color(0xFF221E21);
  static const sidebarLight = Color(0xFFF3EFF2);

  // Content background surfaces
  static const contentDark = Color(0xFF1E1A1D);
  static const contentLight = Color(0xFFFAF7F9);

  // Card surfaces
  static const cardDark = Color(0xFF2E292D);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardBorderDark = Color(0xFF40393F);
  static const cardBorderLight = Color(0xFFE0DAE0);

  /// Builds the light Ubuntu theme fused with Dynamotivation accents.
  ///
  /// Fuses on top of the runtime-resolved Yaru theme (which already follows
  /// the user's GTK theme name, GNOME color-scheme and geometry preferences
  /// live), so only the brand identity colors are overridden.
  static ThemeData light(ThemeData yaruBase) {
    return yaruBase.copyWith(
      colorScheme: yaruBase.colorScheme.copyWith(
        primary: ubuntuOrange,
        secondary: coralAccent,
        surface: contentLight,
      ),
      scaffoldBackgroundColor: contentLight,
      dividerColor: cardBorderLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: headerLight,
        foregroundColor: Color(0xFF111111),
        elevation: 0,
      ),
    );
  }

  /// Builds the dark Ubuntu theme fused with Dynamotivation accents.
  static ThemeData dark(ThemeData yaruBase) {
    return yaruBase.copyWith(
      colorScheme: yaruBase.colorScheme.copyWith(
        primary: ubuntuOrange,
        secondary: coralAccent,
        surface: contentDark,
      ),
      scaffoldBackgroundColor: contentDark,
      dividerColor: cardBorderDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: headerDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  /// High-contrast themes follow the accessibility requirement, not brand:
  /// contrast rules trump corporate identity colors, matching the Ubuntu
  /// App Center, which hands the stock `yaru` high-contrast themes to
  /// `MaterialApp.highContrastTheme`.
  static ThemeData highContrastLight(ThemeData yaruBase) => yaruBase.copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111111),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );

  static ThemeData highContrastDark(ThemeData yaruBase) => yaruBase.copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111111),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
}
