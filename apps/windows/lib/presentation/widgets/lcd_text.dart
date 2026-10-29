import 'package:fluent_ui/fluent_ui.dart';

/// Text with fake LCD (ClearType-style) subpixel anti-aliasing.
///
/// Flutter on Windows only draws grayscale text. This paints the same text
/// three times, once per colour channel, each pass shifted by a third of a
/// physical pixel (the R, G and B subpixels sit side by side) and blended so it
/// only touches its own channel. The blend needs the colour behind the text, so
/// [background] must be the real, solid colour under it.
///
/// Only the green pass is a real, selectable [Text]. The red and blue passes
/// are inert: excluded from selection and from semantics, so selecting or
/// reading the text sees one copy.
class LcdText extends StatelessWidget {
  final String data;

  /// Style without a colour; use [color] instead.
  final TextStyle? style;
  final Color color;
  final Color background;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  const LcdText(
    this.data, {
    super.key,
    this.style,
    required this.color,
    required this.background,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    assert(style?.color == null, 'Pass the colour as LcdText.color.');
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final fg = Color.alphaBlend(color, background);
    final third = 1 / (3 * dpr);

    Widget pass(_Channel channel) => Text(
      data,
      style: (style ?? const TextStyle()).copyWith(
        foreground: _channelPaint(channel, fg, background),
      ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
    );

    // The green pass comes first: it sizes the stack and owns the selection
    // highlight, which therefore sits under the other two passes.
    return Stack(
      children: [
        pass(_Channel.green),
        Positioned.fill(
          child: SelectionContainer.disabled(
            child: ExcludeSemantics(
              child: Transform.translate(
                offset: Offset(third, 0),
                child: pass(_Channel.red),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: SelectionContainer.disabled(
            child: ExcludeSemantics(
              child: Transform.translate(
                offset: Offset(-third, 0),
                child: pass(_Channel.blue),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _Channel { red, green, blue }

/// Paint that moves one colour channel from [bg] towards [fg] in proportion to
/// the glyph coverage, and leaves the other two channels alone.
///
/// Coverage-weighted blending gives `out = dst * (1 - a) + blend(src, dst) * a`
/// for the pixels the glyph touches:
/// - multiply, `blend = dst * s`, darkens the channel: `s = fg / bg`.
/// - screen, `blend = dst + s * (1 - dst)`, lightens it: `s = (fg - bg) / (1 - bg)`.
/// Both land exactly on `fg` at full coverage. The untouched channels get the
/// neutral source for the mode (1 for multiply, 0 for screen).
Paint _channelPaint(_Channel channel, Color fg, Color bg) {
  double pick(Color c) => switch (channel) {
    _Channel.red => c.r,
    _Channel.green => c.g,
    _Channel.blue => c.b,
  };
  final f = pick(fg);
  final b = pick(bg);
  final darken = f <= b;
  final s = darken ? (b == 0 ? 1.0 : f / b) : (f - b) / (1 - b);
  final neutral = darken ? 1.0 : 0.0;
  Color build(double value) => Color.from(
    alpha: 1,
    red: channel == _Channel.red ? value : neutral,
    green: channel == _Channel.green ? value : neutral,
    blue: channel == _Channel.blue ? value : neutral,
  );
  return Paint()
    ..color = build(s.clamp(0.0, 1.0))
    ..blendMode = darken ? BlendMode.multiply : BlendMode.screen;
}
