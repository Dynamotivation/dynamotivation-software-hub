import 'package:fluent_ui/fluent_ui.dart';

import '../../platform/windows_accessibility.dart';

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

  /// Use the chosen Windows contrast colors without brand substitutions.
  static DynTokens fromSystem(WindowsContrastPalette palette) => DynTokens._(
    isDark: palette.window.computeLuminance() < 0.5,
    headerGradient: LinearGradient(colors: [palette.window, palette.window]),
    headerForeground: palette.text,
    headerMuted: palette.text,
    headerHover: palette.window,
    headerPill: palette.window,
    brandAccent: palette.text,
    brandRed: palette.text,
    critical: palette.text,
    success: palette.text,
    primary: palette.highlight,
    primaryHover: palette.highlight,
    primaryPressed: palette.highlight,
    secondary: palette.button,
    secondaryHover: palette.button,
    secondaryPressed: palette.button,
    secondaryBorder: palette.text,
    updateBadge: palette.window,
    neutralBadge: palette.window,
    window: palette.window,
    card: palette.window,
    cardBorder: palette.text,
    popup: palette.window,
    hover: palette.window,
    selected: palette.window,
    divider: palette.text,
    scrollbarThumb: palette.text,
    progressTrack: palette.window,
    text: palette.text,
    textMuted: palette.text,
    textSubtle: palette.text,
  );

  /// Tokens for users with high contrast enabled: translucent text and
  /// hairlines become fully opaque, overlays and borders grow stronger.
  /// Contrast requirements trump both brand and Fluent-light styling.
  static DynTokens highContrast(DynTokens base) => fromSystem(
    WindowsContrastPalette(
      enabled: true,
      window: base.isDark ? Colors.black : Colors.white,
      text: base.isDark ? Colors.white : Colors.black,
      button: base.isDark ? Colors.black : Colors.white,
      buttonText: base.isDark ? Colors.white : Colors.black,
      highlight: base.isDark ? Colors.white : Colors.black,
      highlightText: base.isDark ? Colors.black : Colors.white,
      disabled: base.isDark ? Colors.white : Colors.black,
    ),
  );

  /// The tokens for the current brightness, with strengthened contrast when
  /// the user has high contrast enabled.
  static DynTokens of(BuildContext context) {
    final tokens = FluentTheme.of(context).brightness == Brightness.dark
        ? dark
        : light;
    final palette = WindowsContrastScope.of(context);
    if (palette != null) return palette.enabled ? fromSystem(palette) : tokens;
    return MediaQuery.highContrastOf(context) ? highContrast(tokens) : tokens;
  }
}

class DynamotivationTheme {
  static const captionCloseHover = Color(0xFFE81123);
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

  static FluentThemeData systemContrastTheme(WindowsContrastPalette palette) {
    final brightness = palette.window.computeLuminance() < 0.5
        ? Brightness.dark
        : Brightness.light;
    final resources = ResourceDictionary.raw(
      textFillColorPrimary: palette.text,
      textFillColorSecondary: palette.text,
      textFillColorTertiary: palette.text,
      textFillColorDisabled: palette.disabled,
      textFillColorInverse: palette.highlightText,
      accentTextFillColorDisabled: palette.disabled,
      textOnAccentFillColorSelectedText: palette.highlightText,
      textOnAccentFillColorPrimary: palette.highlightText,
      textOnAccentFillColorSecondary: palette.highlightText,
      textOnAccentFillColorDisabled: palette.disabled,
      controlFillColorDefault: palette.button,
      controlFillColorSecondary: palette.button,
      controlFillColorTertiary: palette.button,
      controlFillColorQuarternary: palette.button,
      controlFillColorDisabled: palette.button,
      controlFillColorTransparent: palette.window,
      controlFillColorInputActive: palette.button,
      controlStrongFillColorDefault: palette.button,
      controlStrongFillColorDisabled: palette.disabled,
      controlSolidFillColorDefault: palette.button,
      subtleFillColorTransparent: palette.window,
      subtleFillColorSecondary: palette.window,
      subtleFillColorTertiary: palette.window,
      subtleFillColorDisabled: palette.window,
      controlAltFillColorTransparent: palette.window,
      controlAltFillColorSecondary: palette.button,
      controlAltFillColorTertiary: palette.button,
      controlAltFillColorQuarternary: palette.button,
      controlAltFillColorDisabled: palette.button,
      controlOnImageFillColorDefault: palette.button,
      controlOnImageFillColorSecondary: palette.button,
      controlOnImageFillColorTertiary: palette.button,
      controlOnImageFillColorDisabled: palette.button,
      accentFillColorDisabled: palette.highlight,
      controlStrokeColorDefault: palette.text,
      controlStrokeColorSecondary: palette.text,
      controlStrokeColorOnAccentDefault: palette.text,
      controlStrokeColorOnAccentSecondary: palette.text,
      controlStrokeColorOnAccentTertiary: palette.text,
      controlStrokeColorOnAccentDisabled: palette.disabled,
      controlStrokeColorForStrongFillWhenOnImage: palette.text,
      cardStrokeColorDefault: palette.text,
      cardStrokeColorDefaultSolid: palette.text,
      controlStrongStrokeColorDefault: palette.text,
      controlStrongStrokeColorDisabled: palette.disabled,
      surfaceStrokeColorDefault: palette.text,
      surfaceStrokeColorFlyout: palette.text,
      surfaceStrokeColorInverse: palette.text,
      dividerStrokeColorDefault: palette.text,
      focusStrokeColorOuter: palette.text,
      focusStrokeColorInner: palette.text,
      cardBackgroundFillColorDefault: palette.window,
      cardBackgroundFillColorSecondary: palette.window,
      cardBackgroundFillColorTertiary: palette.window,
      smokeFillColorDefault: palette.window,
      layerFillColorDefault: palette.window,
      layerFillColorAlt: palette.window,
      layerOnAcrylicFillColorDefault: palette.window,
      layerOnAccentAcrylicFillColorDefault: palette.window,
      layerOnMicaBaseAltFillColorDefault: palette.window,
      layerOnMicaBaseAltFillColorSecondary: palette.window,
      layerOnMicaBaseAltFillColorTertiary: palette.window,
      layerOnMicaBaseAltFillColorTransparent: palette.window,
      solidBackgroundFillColorBase: palette.window,
      solidBackgroundFillColorSecondary: palette.window,
      solidBackgroundFillColorTertiary: palette.window,
      solidBackgroundFillColorQuarternary: palette.window,
      solidBackgroundFillColorQuinary: palette.window,
      solidBackgroundFillColorSenary: palette.window,
      solidBackgroundFillColorTransparent: palette.window,
      solidBackgroundFillColorBaseAlt: palette.window,
      systemFillColorSuccess: palette.text,
      systemFillColorCaution: palette.text,
      systemFillColorCritical: palette.text,
      systemFillColorNeutral: palette.text,
      systemFillColorSolidNeutral: palette.text,
      systemFillColorAttentionBackground: palette.window,
      systemFillColorSuccessBackground: palette.window,
      systemFillColorCautionBackground: palette.window,
      systemFillColorCriticalBackground: palette.window,
      systemFillColorNeutralBackground: palette.window,
      systemFillColorSolidAttentionBackground: palette.window,
      systemFillColorSolidNeutralBackground: palette.window,
    );
    return FluentThemeData(
      brightness: brightness,
      resources: resources,
      typography: Typography.fromBrightness(color: palette.text),
      accentColor: AccentColor.swatch({
        for (final key in [
          'darkest',
          'darker',
          'dark',
          'normal',
          'light',
          'lighter',
          'lightest',
        ])
          key: palette.highlight,
      }),
      activeColor: palette.highlightText,
      inactiveColor: palette.text,
      inactiveBackgroundColor: palette.button,
      scaffoldBackgroundColor: palette.window,
      cardColor: palette.window,
      menuColor: palette.window,
      micaBackgroundColor: palette.window,
      acrylicBackgroundColor: palette.window,
      acrylicFallbackColor: palette.window,
      selectionColor: palette.highlight,
      shadowColor: Colors.transparent,
      iconTheme: IconThemeData(color: palette.text),
      focusTheme: FocusThemeData(
        primaryBorder: BorderSide(color: palette.text, width: 2),
        secondaryBorder: BorderSide(color: palette.window),
        glowFactor: 0,
      ),
      buttonTheme: ButtonThemeData(
        defaultButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(palette.button),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.isDisabled ? palette.disabled : palette.buttonText,
          ),
        ),
        filledButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.isDisabled ? palette.button : palette.highlight,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.isDisabled ? palette.disabled : palette.highlightText,
          ),
        ),
      ),
    );
  }

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
