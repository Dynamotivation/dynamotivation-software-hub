import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Standard scroll physics preserve touch, keyboard and accessibility scrolling.
const ScrollPhysics smoothScrollPhysics = ClampingScrollPhysics();

/// Eases wheel input at the position boundary, after Flutter resolves nested
/// scrollables. Other input paths retain the framework's normal behavior.
class SmoothScrollController extends ScrollController {
  bool _disableAnimations = false;

  SmoothScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });

  set disableAnimations(bool value) {
    _disableAnimations = value;
    if (value) {
      for (final position in positions) {
        (position as _SmoothScrollPosition).finishWheel();
      }
    }
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _SmoothScrollPosition(
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    oldPosition: oldPosition,
    disableMotion: () => _disableAnimations,
  );
}

class _SmoothScrollPosition extends ScrollPositionWithSingleContext {
  final bool Function() disableMotion;
  double? _wheelTarget;
  int _generation = 0;

  _SmoothScrollPosition({
    required super.physics,
    required super.context,
    required super.initialPixels,
    required super.keepScrollOffset,
    super.oldPosition,
    required this.disableMotion,
  });

  void finishWheel() {
    final target = _wheelTarget;
    _wheelTarget = null;
    _generation++;
    if (target != null && hasPixels) jumpTo(target);
  }

  @override
  void pointerScroll(double delta) {
    if (disableMotion()) {
      finishWheel();
      super.pointerScroll(delta);
      return;
    }
    final base = _wheelTarget != null && isScrollingNotifier.value
        ? _wheelTarget!
        : pixels;
    final target = (base + delta).clamp(minScrollExtent, maxScrollExtent);
    _wheelTarget = target;
    final generation = ++_generation;
    animateTo(
      target,
      duration: Duration(
        milliseconds: (140 + (target - pixels).abs() * .35)
            .clamp(140, 380)
            .round(),
      ),
      curve: Curves.easeOutCubic,
    ).whenComplete(() {
      if (generation == _generation) _wheelTarget = null;
    });
  }
}

/// Connects motion preferences to an owned [SmoothScrollController].
/// A regular ScrollController is also supported, using native wheel behavior.
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

class _SmoothScrollState extends State<SmoothScroll> {
  // Keep keyboard routing inside the scroll view when lazy children are
  // disposed after paging. Parent-scope traversal avoids trapping Tab here.
  final _focusScope = FocusScopeNode(
    debugLabel: 'Scroll content',
    traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );

  void _page(double direction) {
    final controller = widget.controller;
    if (!controller.hasClients) return;
    final position = controller.position;
    final target =
        (position.pixels + direction * position.viewportDimension * .8).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      controller.jumpTo(target);
    } else {
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _focusScope.dispose();
    super.dispose();
  }

  void _syncMotion() {
    final controller = widget.controller;
    if (controller is SmoothScrollController) {
      controller.disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant SmoothScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.pageDown): () => _page(1),
      const SingleActivator(LogicalKeyboardKey.pageUp): () => _page(-1),
    },
    child: FocusScope(node: _focusScope, child: widget.child),
  );
}
