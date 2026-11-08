import 'package:fluent_ui/fluent_ui.dart';

/// One slot of the detail banner's actions. Its content may change (Install
/// → Downloading → Installing → Launch, Launch → Running + close); the slot
/// animates to the new content's width instead of jumping, and never uses a
/// fixed width. Instant when the system asks for reduced motion.
class AnimatedActionWidth extends StatelessWidget {
  final Widget child;

  const AnimatedActionWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
    alignment: AlignmentDirectional.centerStart,
    child: child,
  );
}
