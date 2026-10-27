import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Eased mouse-wheel scrolling.
///
/// Flutter applies each wheel notch as an instant jump, which looks harsh on
/// Windows. This wraps a scrollable, turns wheel deltas into a short eased
/// animation towards an accumulated target, and keeps the scrollable itself
/// from also jumping: give it [smoothScrollPhysics]. Dragging the scrollbar
/// thumb and programmatic scrolling still work through [controller].
class SmoothScroll extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const SmoothScroll({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

/// Physics for the scrollable inside a [SmoothScroll]: it ignores wheel and
/// drag input, because [SmoothScroll] drives the position instead.
const ScrollPhysics smoothScrollPhysics = NeverScrollableScrollPhysics();

class _SmoothScrollState extends State<SmoothScroll> {
  double? _target;

  void _onSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final c = widget.controller;
    if (!c.hasClients) return;
    final position = c.position;
    // Continue from the running target so fast wheel spins accumulate.
    final base = (_target != null && position.isScrollingNotifier.value)
        ? _target!
        : position.pixels;
    final target = (base + event.scrollDelta.dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _target = target;
    final distance = (target - position.pixels).abs();
    c.animateTo(
      target,
      duration: Duration(
        milliseconds: (140 + distance * 0.35).clamp(140, 380).round(),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) =>
      Listener(onPointerSignal: _onSignal, child: widget.child);
}
