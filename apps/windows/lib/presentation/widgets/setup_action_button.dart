import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../theme/dynamotivation_theme.dart';

/// Install, Update or Uninstall. While its setup runs, the same button turns
/// into a progress button: a spinner and status text, with a download
/// filling the button from left to right. Sized by what it shows; the detail
/// banner animates width changes (`AnimatedActionWidth`). It only turns back
/// (or goes away, when the setup changed what is installed) once the setup
/// succeeded or failed.
class SetupActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Status shown once the setup or uninstaller itself runs.
  final String runningStatus;

  /// True while this package's setup runs.
  final bool inProgress;

  /// 0 to 1 while the setup downloads, null once it runs.
  final double? downloadFraction;

  /// False while any other setup runs or the action is not available.
  final bool enabled;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  /// The idle look: filled for install and update, standard otherwise.
  final bool filled;

  const SetupActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.runningStatus,
    this.inProgress = false,
    this.downloadFraction,
    required this.enabled,
    this.onPressed,
    this.focusNode,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!inProgress) return _button(context, focus: focusNode, text: label);
    // An invisible button with the status as its label gives the progress
    // surface a real button's height and padding at the status's width.
    return Stack(
      children: [
        ExcludeSemantics(
          child: ExcludeFocus(
            child: IgnorePointer(
              child: Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _button(context, text: _status(context)),
              ),
            ),
          ),
        ),
        Positioned.fill(child: _progress(context)),
      ],
    );
  }

  String _status(BuildContext context) {
    final fraction = downloadFraction;
    return fraction == null
        ? runningStatus
        : context.l10n.setupDownloading((fraction * 100).round());
  }

  Widget _button(
    BuildContext context, {
    FocusNode? focus,
    required String text,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 6),
          Flexible(child: Text(text, maxLines: 1)),
        ],
      ),
    );
    final pressed = enabled && !inProgress ? onPressed : null;
    return filled
        ? FilledButton(focusNode: focus, onPressed: pressed, child: child)
        : Button(
            focusNode: focus,
            style: DynamotivationTheme.secondaryActionStyle(context),
            onPressed: pressed,
            child: child,
          );
  }

  Widget _progress(BuildContext context) {
    final theme = FluentTheme.of(context);
    final tokens = DynTokens.of(context);
    final fraction = downloadFraction;
    final status = _status(context);
    final fill = theme.accentColor.defaultBrushFor(theme.brightness);
    final onFill = theme.resources.textOnAccentFillColorPrimary;
    final track = theme.resources.controlFillColorSecondary;
    final onTrack = theme.resources.textFillColorPrimary;
    final radius = DynamotivationTheme.actionRadius(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget content(Color color) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 13,
            child: reduceMotion
                ? Icon(FluentIcons.sync, size: 13, color: color)
                : ProgressRing(strokeWidth: 2, activeColor: color),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );

    // The status text is drawn twice, in the colour that reads on the fill
    // and in the one that reads on the track, each clipped to its part.
    return Focus(
      focusNode: focusNode,
      child: Semantics(
        container: true,
        liveRegion: true,
        button: true,
        enabled: false,
        label: label,
        value: status,
        excludeSemantics: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction ?? 1.0),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          builder: (context, value, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: track,
              borderRadius: radius,
              border: Border.all(
                color: Focus.of(context).hasFocus
                    ? theme.resources.focusStrokeColorOuter
                    : tokens.cardBorder,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(child: content(onTrack)),
                  ClipRect(
                    clipper: _LeftPart(value),
                    child: ColoredBox(
                      color: fill,
                      child: Center(child: content(onFill)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftPart extends CustomClipper<Rect> {
  final double fraction;
  const _LeftPart(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction.clamp(0.0, 1.0), size.height);

  @override
  bool shouldReclip(_LeftPart old) => old.fraction != fraction;
}
