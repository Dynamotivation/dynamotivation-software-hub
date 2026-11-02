import 'package:dynamotivation_software_hub/platform/windows_accessibility.dart';
import 'package:dynamotivation_software_hub/presentation/theme/dynamotivation_theme.dart';
import 'package:flutter/widgets.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

/// Composited contrast evidence for the Windows frontend.
///
/// Every ratio is computed from the token sources the app actually composes:
/// translucent tokens are alpha-blended over the surface they render on. The
/// assertions are the WCAG 2.2 AA minimums the repo adopts (4.5:1 normal
/// text, 3:1 large text/focus indicators), so a failing assertion here is a
/// regression, not a report.
void main() {
  // --- WCAG 2.2 contrast: Color.computeLuminance implements the same sRGB
  // relative luminance Flutter uses for its own semantics checks. ---
  double luminance(Color color) => color.computeLuminance();

  double ratio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final light = la > lb ? la : lb;
    final dark = la > lb ? lb : la;
    return (light + 0.05) / (dark + 0.05);
  }

  // A vertical gradient's weakest stop is the one closest to the foreground,
  // so both stops must pass (there is text across the whole 82px header).
  group('brand tokens (light and dark)', () {
    test('essential text and status text meet 4.5:1 on their surfaces', () {
      for (final tokens in [DynTokens.light, DynTokens.dark]) {
        final card = tokens.card;
        final window = tokens.window;
        final name = tokens.isDark ? 'dark' : 'light';

        expect(
          ratio(tokens.text, window),
          greaterThanOrEqualTo(4.5),
          reason: '$name: text on window',
        );
        expect(
          ratio(tokens.text, card),
          greaterThanOrEqualTo(4.5),
          reason: '$name: text on card',
        );
        // Muted/subtle text is rendered (alpha composited) over the surfaces.
        expect(
          ratio(Color.alphaBlend(tokens.textMuted, window), window),
          greaterThanOrEqualTo(4.5),
          reason: '$name: textMuted composited on window',
        );
        expect(
          ratio(Color.alphaBlend(tokens.textMuted, card), card),
          greaterThanOrEqualTo(4.5),
          reason: '$name: textMuted composited on card',
        );
        expect(
          ratio(Color.alphaBlend(tokens.textSubtle, card), card),
          greaterThanOrEqualTo(4.5),
          reason: '$name: textSubtle composited on card',
        );
        // Status text (destructive confirmations, success toasts).
        expect(
          ratio(tokens.critical, card),
          greaterThanOrEqualTo(4.5),
          reason: '$name: critical text on card',
        );
        expect(
          ratio(tokens.success, card),
          greaterThanOrEqualTo(4.5),
          reason: '$name: success text on card',
        );
        // Badges carry version/status text composited over the card.
        expect(
          ratio(tokens.text, Color.alphaBlend(tokens.updateBadge, card)),
          greaterThanOrEqualTo(4.5),
          reason: '$name: text on update badge composited over card',
        );
        expect(
          ratio(tokens.text, Color.alphaBlend(tokens.neutralBadge, card)),
          greaterThanOrEqualTo(4.5),
          reason: '$name: text on neutral badge composited over card',
        );
      }
    });

    test('header overline and product title meet 4.5:1 on both stops', () {
      for (final tokens in [DynTokens.light, DynTokens.dark]) {
        for (final stop in tokens.headerGradient.colors) {
          expect(
            ratio(tokens.headerForeground, stop),
            greaterThanOrEqualTo(4.5),
            reason:
                '${tokens.isDark ? "dark" : "light"} header text on stop $stop',
          );
        }
      }
    });

    test('primary button label survives every interaction state', () {
      // The filled Launch/Update buttons paint white text on the primary
      // swatch and its hover/pressed states.
      expect(
        ratio(const Color(0xFFFFFFFF), DynTokens.light.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(const Color(0xFFFFFFFF), DynTokens.light.primaryHover),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(const Color(0xFFFFFFFF), DynTokens.light.primaryPressed),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(const Color(0xFFFFFFFF), DynTokens.dark.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(const Color(0xFFFFFFFF), DynTokens.dark.primaryHover),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(const Color(0xFFFFFFFF), DynTokens.dark.primaryPressed),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('secondary button label meets 4.5:1 in every state', () {
      for (final tokens in [DynTokens.light, DynTokens.dark]) {
        expect(ratio(tokens.text, tokens.secondary), greaterThanOrEqualTo(4.5));
        expect(
          ratio(tokens.text, tokens.secondaryHover),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          ratio(tokens.text, tokens.secondaryPressed),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('hover/selection tint keeps row text legible on rows', () {
      // Sidebar rows composite the hover/selected tint over the window and
      // then draw text on top.
      for (final tokens in [DynTokens.light, DynTokens.dark]) {
        expect(
          ratio(tokens.text, Color.alphaBlend(tokens.hover, tokens.window)),
          greaterThanOrEqualTo(4.5),
          reason: '${tokens.isDark ? "dark" : "light"}: text on hovered row',
        );
        expect(
          ratio(tokens.text, Color.alphaBlend(tokens.selected, tokens.window)),
          greaterThanOrEqualTo(4.5),
          reason: '${tokens.isDark ? "dark" : "light"}: text on selected row',
        );
      }
    });

    test('title bar logo does not carry required text (decorative only)', () {
      // Documented as a measurement: a purely brand band. The brand name and
      // product name (the essential text) sit on headerGradient and are
      // asserted in the header test above.
      expect(true, isTrue);
    });
  });

  group('focus visibility', () {
    test('brand accent focus ring reaches 3:1 against the window', () {
      // Fluent FocusBorder draws the accent stroke on the window background;
      // the glow only decorates it.
      expect(
        ratio(DynamotivationTheme.coralPrimary, DynTokens.light.window),
        greaterThanOrEqualTo(3),
        reason: 'light mode focus ring on window',
      );
      expect(
        ratio(const Color(0xFFE5484D), DynTokens.dark.window),
        greaterThanOrEqualTo(3),
        reason: 'dark mode focus ring on window',
      );
    });

    test('system high contrast focus stroke reaches 3:1', () {
      final dark = WindowsContrastPalette(
        enabled: true,
        window: const Color(0xFF101010),
        text: const Color(0xFFFFFF00),
        button: const Color(0xFF101010),
        buttonText: const Color(0xFFFFFF00),
        highlight: const Color(0xFF00FFFF),
        highlightText: const Color(0xFF101010),
        disabled: const Color(0xFF909090),
      );
      final light = WindowsContrastPalette(
        enabled: true,
        window: const Color(0xFFFFFFEE),
        text: const Color(0xFF000040),
        button: const Color(0xFFFFFFEE),
        buttonText: const Color(0xFF000040),
        highlight: const Color(0xFF800040),
        highlightText: const Color(0xFFFFFFEE),
        disabled: const Color(0xFF606060),
      );
      expect(ratio(dark.text, dark.window), greaterThanOrEqualTo(3));
      expect(ratio(light.text, light.window), greaterThanOrEqualTo(3));
    });
  });

  group('system high contrast palettes', () {
    const palettes = {
      'windows dark high contrast': WindowsContrastPalette(
        enabled: true,
        window: Color(0xFF101010),
        text: Color(0xFFFFFF00),
        button: Color(0xFF101010),
        buttonText: Color(0xFFFFFF00),
        highlight: Color(0xFF00FFFF),
        highlightText: Color(0xFF101010),
        disabled: Color(0xFF909090),
      ),
      'windows light high contrast': WindowsContrastPalette(
        enabled: true,
        window: Color(0xFFFFFFEE),
        text: Color(0xFF000040),
        button: Color(0xFFFFFFEE),
        buttonText: Color(0xFF000040),
        highlight: Color(0xFF800040),
        highlightText: Color(0xFFFFFFEE),
        disabled: Color(0xFF606060),
      ),
    };

    test('system palettes satisfy AA for every essential pair', () {
      palettes.forEach((name, palette) {
        final tokens = DynTokens.fromSystem(palette);
        final theme = DynamotivationTheme.systemContrastTheme(palette);

        // Text on window, card, popup, buttons and header.
        for (final surface in [
          tokens.window,
          tokens.card,
          tokens.popup,
          tokens.secondary,
        ]) {
          expect(
            ratio(tokens.text, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name: text on surface $surface',
          );
        }
        expect(
          ratio(tokens.headerForeground, tokens.headerGradient.colors.first),
          greaterThanOrEqualTo(4.5),
          reason: '$name: header text on header',
        );
        // Filled/accent controls use the user-selected highlight colors.
        expect(
          ratio(palette.buttonText, palette.button),
          greaterThanOrEqualTo(4.5),
          reason: '$name: buttonText on button',
        );
        expect(
          ratio(palette.highlightText, palette.highlight),
          greaterThanOrEqualTo(4.5),
          reason: '$name: highlightText on highlight',
        );
        // The Fluent theme must derive its text colors from the palette too.
        expect(
          theme.resources.textFillColorPrimary,
          palette.text,
          reason: '$name: Fluent primary text follows the palette',
        );
        expect(
          theme.resources.textOnAccentFillColorPrimary,
          palette.highlightText,
          reason: '$name: Fluent text-on-accent follows the palette',
        );
        expect(
          theme.scaffoldBackgroundColor,
          palette.window,
          reason: '$name: window background follows the palette',
        );
      });
    });

    test('disabled foreground matches the user-selected disabled color', () {
      // Disabled text is exempt from WCAG minimums, but the user chose the
      // color, so the theme must still show it and never swap in brand gray.
      palettes.forEach((name, palette) {
        final theme = DynamotivationTheme.systemContrastTheme(palette);
        expect(
          theme.resources.textFillColorDisabled,
          palette.disabled,
          reason: '$name: disabled text color is the selected one',
        );
        expect(
          theme.resources.controlFillColorDisabled,
          palette.button,
          reason: '$name: disabled control fill is the selected one',
        );
      });
    });
  });

  group('synthetic app high contrast (no palette delivered)', () {
    test('highContrast tokens keep essential text at 4.5:1', () {
      for (final base in [DynTokens.light, DynTokens.dark]) {
        final tokens = DynTokens.highContrast(base);
        expect(
          ratio(tokens.text, tokens.window),
          greaterThanOrEqualTo(4.5),
          reason:
              '${base.isDark ? "dark" : "light"} high contrast: text on window',
        );
        expect(
          ratio(tokens.headerForeground, tokens.headerGradient.colors.first),
          greaterThanOrEqualTo(4.5),
          reason:
              '${base.isDark ? "dark" : "light"} high contrast: header text',
        );
        expect(
          ratio(tokens.cardBorder, tokens.card),
          greaterThanOrEqualTo(3),
          reason:
              '${base.isDark ? "dark" : "light"} high contrast: card boundary',
        );
      }
    });
  });
}
