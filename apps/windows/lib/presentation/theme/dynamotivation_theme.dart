import 'package:fluent_ui/fluent_ui.dart';

/// Dynamotivation colour tokens.
/// Keep names and values in sync with that file so both apps look the same.
class DynTokens {
  final bool isDark;

  // Header banner: 135deg gradient, top-left to bottom-right.
  final LinearGradient headerGradient;
  final Color headerForeground;
  final Color headerMuted;
  final Color headerHover;
  final Color headerPill;

  // Brand
  final Color brandAccent;
  final Color brandRed;
  final Color critical;
  final Color success;

  // Primary / secondary buttons
  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color secondary;
  final Color secondaryHover;
  final Color secondaryPressed;
  final Color secondaryBorder;

  // Badges
  final Color updateBadge;
  final Color neutralBadge;

  // Surfaces
  final Color window;
  final Color card;
  final Color cardBorder;
  final Color popup;
  final Color hover;
  final Color selected;
  final Color divider;
  final Color scrollbarThumb;
  final Color progressTrack;

  // Text
  final Color text;
  final Color textMuted;
  final Color textSubtle;

  const DynTokens._({
    required this.isDark,
    required this.headerGradient,
    required this.headerForeground,
    required this.headerMuted,
    required this.headerHover,
    required this.headerPill,
    required this.brandAccent,
    required this.brandRed,
    required this.critical,
    required this.success,
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.secondary,
    required this.secondaryHover,
    required this.secondaryPressed,
    required this.secondaryBorder,
    required this.updateBadge,
    required this.neutralBadge,
    required this.window,
    required this.card,
    required this.cardBorder,
    required this.popup,
    required this.hover,
    required this.selected,
    required this.divider,
    required this.scrollbarThumb,
    required this.progressTrack,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
  });

  static const light = DynTokens._(
    isDark: false,
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      // 20% dark scrim over the brand gradient: white text >= 4.5:1.
      colors: [Color(0xFFCC3C3B), Color(0xFF893750)],
    ),
    headerForeground: Color(0xFFFFFFFF),
    headerMuted: Color(0xFFFFFFFF),
    headerHover: Color(0x29FFFFFF),
    headerPill: Color(0x2EFFFFFF),
    brandAccent: Color(0xFFE22050),
    brandRed: Color(0xFFD61F45),
    critical: Color(0xFFC42B1C),
    success: Color(0xFF0F7A48),
    primary: Color(0xFFE22050),
    primaryHover: Color(0xFFC91A45),
    primaryPressed: Color(0xFFB0163C),
    secondary: Color(0xFFFFFFFF),
    secondaryHover: Color(0xFFF7F1F4),
    secondaryPressed: Color(0xFFEFE6EB),
    secondaryBorder: Color(0xFFDDD2D8),
    updateBadge: Color(0x1AE22050),
    neutralBadge: Color(0xFFF3EEF1),
    window: Color(0xFFF5F2F5),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5DCE1),
    popup: Color(0xFFFFFFFF),
    hover: Color(0x0F893750),
    selected: Color(0x17893750),
    divider: Color(0xFFEEE8EC),
    scrollbarThumb: Color(0xFF8A7D84),
    progressTrack: Color(0x1F893750),
    text: Color(0xFF000000),
    textMuted: Color(0xAD000000),
    textSubtle: Color(0x99000000),
  );

  static const dark = DynTokens._(
    isDark: true,
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF963744), Color(0xFF411B23)],
    ),
    headerForeground: Color(0xFFFFFFFF),
    headerMuted: Color(0xFFFFFFFF),
    headerHover: Color(0x29FFFFFF),
    headerPill: Color(0x2EFFFFFF),
    brandAccent: Color(0xFF38E89F),
    brandRed: Color(0xFFFF6B6B),
    critical: Color(0xFFFF99A4),
    success: Color(0xFF67FFAE),
    primary: Color(0xFFD23A40),
    primaryHover: Color(0xFFC7343A),
    primaryPressed: Color(0xFFB72E34),
    secondary: Color(0xFF2C2F36),
    secondaryHover: Color(0xFF363A42),
    secondaryPressed: Color(0xFF3F434C),
    secondaryBorder: Color(0xFF3F434C),
    updateBadge: Color(0x29FF6B6B),
    neutralBadge: Color(0xFF2C2F36),
    window: Color(0xFF16181B),
    card: Color(0xFF222428),
    cardBorder: Color(0xFF32353C),
    popup: Color(0xFF2A2D33),
    hover: Color(0x0FFFFFFF),
    selected: Color(0x17FFFFFF),
    divider: Color(0xFF2E3138),
    scrollbarThumb: Color(0xFF7A808C),
    progressTrack: Color(0x1FFFFFFF),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xADFFFFFF),
    textSubtle: Color(0x99FFFFFF),
  );

  /// Tokens for users with high contrast enabled: translucent text and
  /// hairlines become fully opaque, overlays and borders grow stronger.
  /// Contrast requirements trump both brand and Fluent-light styling.
  static DynTokens highContrast(DynTokens base) {
    final isDark = base.isDark;
    return DynTokens._(
      isDark: base.isDark,
      headerGradient: base.headerGradient,
      headerForeground: base.headerForeground,
      headerMuted: base.headerMuted,
      headerHover: isDark ? const Color(0x33FFFFFF) : const Color(0x33000000),
      headerPill: isDark ? const Color(0x40FFFFFF) : const Color(0x40000000),
      brandAccent: base.brandAccent,
      brandRed: base.brandRed,
      critical: base.critical,
      success: isDark ? const Color(0xFF8DFFC4) : const Color(0xFF006734),
      primary: base.primary,
      primaryHover: base.primaryHover,
      primaryPressed: base.primaryPressed,
      secondary: base.secondary,
      secondaryHover: base.secondaryHover,
      secondaryPressed: base.secondaryPressed,
      secondaryBorder: isDark
          ? const Color(0xFF6A6F7B)
          : const Color(0xFF8A7D84),
      updateBadge: base.updateBadge,
      neutralBadge: base.neutralBadge,
      window: base.window,
      card: base.card,
      cardBorder: isDark ? const Color(0xFF4A4E58) : const Color(0xFF8A7D84),
      popup: base.popup,
      hover: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
      selected: isDark ? const Color(0x33FFFFFF) : const Color(0x33000000),
      divider: isDark ? const Color(0xFF4A4E58) : const Color(0xFF8A7D84),
      scrollbarThumb: isDark
          ? const Color(0xFFB8BEC8)
          : const Color(0xFF5A5560),
      progressTrack: isDark ? const Color(0x33FFFFFF) : const Color(0x33000000),
      text: base.text,
      textMuted: base.text,
      textSubtle: base.text,
    );
  }

  /// The tokens for the current brightness, with strengthened contrast when
  /// the user has high contrast enabled.
  static DynTokens of(BuildContext context) {
    final tokens = FluentTheme.of(context).brightness == Brightness.dark
        ? dark
        : light;
    return MediaQuery.highContrastOf(context) ? highContrast(tokens) : tokens;
  }
}

class DynamotivationTheme {
  // Signature Dynamotivation coral/crimson brand accent
  static const Color coralPrimary = Color(0xFFE22050);
  static const Color coralDark = Color(0xFFC91A45);
  static const Color coralDarker = Color(0xFFB0163C);
  static const Color coralDarkest = Color(0xFF893750);
  static const Color coralLight = Color(0xFFEA3B66);
  static const Color coralLighter = Color(0xFFF05A7E);
  static const Color coralLightest = Color(0xFFF794AC);

  // Mint & cyan signature accent
  static const Color mintAccent = Color(0xFF4AFF83);
  static const Color cyanAccent = Color(0xFF3DFFE5);
  static const Color mintDark = Color(0xFF38E89F);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mintAccent, cyanAccent],
  );

  // AccentColor swatch for FluentUI
  static final AccentColor accentColor = AccentColor.swatch(const {
    'darkest': coralDarkest,
    'darker': coralDarker,
    'dark': coralDark,
    'normal': coralPrimary,
    'light': coralLight,
    'lighter': coralLighter,
    'lightest': coralLightest,
  });

  // Dark mode accent
  static final AccentColor accentColorDark = AccentColor.swatch(const {
    'darkest': Color(0xFF893750),
    'darker': Color(0xFF963744),
    'dark': Color(0xFFC91A45),
    'normal': Color(0xFFE5484D),
    'light': Color(0xFFF05A5F),
    'lighter': Color(0xFFFF6B6B),
    'lightest': Color(0xFFFF8B8B),
  });

  static FluentThemeData lightTheme() {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: accentColor,
      scaffoldBackgroundColor: DynTokens.light.window,
      cardColor: DynTokens.light.card,
      micaBackgroundColor: DynTokens.light.window,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      focusTheme: FocusThemeData(
        glowColor: coralPrimary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8.0),
      ),
      buttonTheme: ButtonThemeData(
        filledButtonStyle: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.isPressed) return coralDarker;
            if (states.isHovered) return coralDark;
            return coralPrimary;
          }),
        ),
      ),
    );
  }

  static FluentThemeData darkTheme() {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: accentColorDark,
      scaffoldBackgroundColor: DynTokens.dark.window,
      cardColor: DynTokens.dark.card,
      micaBackgroundColor: DynTokens.dark.window,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      focusTheme: FocusThemeData(
        glowColor: const Color(0xFFE5484D).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8.0),
      ),
      buttonTheme: ButtonThemeData(
        filledButtonStyle: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            // White label needs >= 4.5:1, so hover darkens instead of lightens.
            if (states.isPressed) return const Color(0xFFB72E34);
            if (states.isHovered) return const Color(0xFFC7343A);
            return const Color(0xFFD23A40);
          }),
        ),
      ),
    );
  }
}
