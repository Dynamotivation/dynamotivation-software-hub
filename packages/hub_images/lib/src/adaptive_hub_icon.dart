import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';

import 'hub_icon.dart';

/// What the pixels of one catalog icon look like.
@immutable
class IconArtwork {
  const IconArtwork._(this.image, this.content);

  final ui.Image image;

  /// The part of [image] that is not transparent, or null when the icon is a
  /// full square (no transparency on its edges) and must be shown whole.
  final Rect? content;

  /// True for icons with transparent edges: they are cropped to [content].
  bool get isTrimmed => content != null;

  /// Width / height of what is shown.
  double get aspect => content == null
      ? 1
      : (content!.width / content!.height).clamp(0.25, 4.0).toDouble();

  /// Pixels at or below this alpha count as transparent.
  static const _transparent = 8;

  static final Map<String, Future<IconArtwork>> _cache = {};

  /// Analyses the icon at [url]; each URL is decoded and scanned once.
  static Future<IconArtwork> load(String url, IconCache icons) => _cache
      .putIfAbsent(url, () => _analyse(url, icons))
      .catchError((Object error) {
        _cache.remove(url);
        throw error;
      });

  /// The result for [url] if it has been analysed already.
  static IconArtwork? peek(String url) => _resolved[url];

  static final Map<String, IconArtwork> _resolved = {};

  static Future<IconArtwork> _analyse(String url, IconCache icons) async {
    final bytes = await icons.bytes(url);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final content = data == null
        ? null
        : _contentOf(data.buffer.asUint8List(), image.width, image.height);
    final artwork = IconArtwork._(image, content);
    _resolved[url] = artwork;
    return artwork;
  }

  /// Bounding box of the non-transparent pixels, or null if every edge is
  /// fully opaque (a full square) or the image is empty.
  static Rect? _contentOf(Uint8List rgba, int width, int height) {
    var left = width, top = height, right = -1, bottom = -1;
    var edgeTransparent = false;
    for (var y = 0; y < height; y++) {
      final row = y * width * 4;
      final onEdgeRow = y == 0 || y == height - 1;
      for (var x = 0; x < width; x++) {
        final alpha = rgba[row + x * 4 + 3];
        final transparent = alpha <= _transparent;
        if (transparent) {
          if (onEdgeRow || x == 0 || x == width - 1) edgeTransparent = true;
          continue;
        }
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
    if (!edgeTransparent || right < left || bottom < top) return null;
    return Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      (right + 1).toDouble(),
      (bottom + 1).toDouble(),
    );
  }
}

/// A catalog icon of fixed [height] whose width follows its artwork.
///
/// Icons that are a full square keep the square and go through [frame], which
/// is where a frontend adds its tile border, shadow and rounded corners.
/// Icons with transparent edges are cropped to their visible shape, scaled to
/// [height] and shown as they are: no frame, no rounding, because the shape is
/// the icon. While the artwork is still being analysed, and when it cannot be
/// loaded, the square [fallback] is shown inside [frame].
class AdaptiveHubIcon extends StatefulWidget {
  const AdaptiveHubIcon({
    super.key,
    required this.url,
    required this.height,
    required this.fallback,
    required this.frame,
  });

  final String? url;
  final double height;
  final Widget fallback;

  /// Wraps a square child (sized [height] by [height]) in the tile decoration.
  final Widget Function(BuildContext context, Widget child) frame;

  @override
  State<AdaptiveHubIcon> createState() => _AdaptiveHubIconState();
}

class _AdaptiveHubIconState extends State<AdaptiveHubIcon> {
  IconArtwork? _artwork;
  bool _failed = false;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(AdaptiveHubIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _resolve();
  }

  void _resolve() {
    final url = widget.url;
    if (url == _loadedFor && (_artwork != null || _failed)) return;
    _loadedFor = url;
    _failed = false;
    _artwork = url == null ? null : IconArtwork.peek(url);
    if (url == null || _artwork != null) return;
    final icons = HubImageScope.of(context);
    IconArtwork.load(url, icons).then(
      (artwork) {
        if (!mounted || widget.url != url) return;
        setState(() => _artwork = artwork);
      },
      onError: (Object error, StackTrace stack) {
        if (!mounted || widget.url != url) return;
        setState(() => _failed = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    final artwork = _artwork;
    if (artwork != null && artwork.isTrimmed) {
      return SizedBox(
        width: height * artwork.aspect,
        height: height,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _TrimmedIconPainter(artwork.image, artwork.content!),
          ),
        ),
      );
    }
    final child = SizedBox(
      width: height,
      height: height,
      child: artwork == null
          ? widget.fallback
          : HubIcon(url: widget.url, fallback: widget.fallback),
    );
    return widget.frame(context, child);
  }
}

class _TrimmedIconPainter extends CustomPainter {
  _TrimmedIconPainter(this.image, this.source);

  final ui.Image image;
  final Rect source;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_TrimmedIconPainter old) =>
      old.image != image || old.source != source;
}
