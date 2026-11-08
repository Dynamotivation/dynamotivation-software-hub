import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../controllers/hub_controller.dart';
import '../theme/dynamotivation_theme.dart';
import 'click_cursor.dart';

/// InfoBar styling for every toast. Fluent paints `info` in the theme accent,
/// which is red here and reads as an error, so informational toasts get a
/// neutral blue instead. Success, warning and error keep Fluent's colours.
/// Both blues meet 3:1 against the card surface they sit on.
InfoBarThemeData hubInfoBarStyle(BuildContext context) {
  final theme = FluentTheme.of(context);
  final base = InfoBarThemeData.standard(theme);
  final info = theme.brightness == Brightness.dark
      ? const Color(0xFF60CDFF)
      : const Color(0xFF005FB8);
  return InfoBarThemeData(
    iconColor: (severity) => severity == InfoBarSeverity.info
        ? info
        : base.iconColor?.call(severity),
  );
}

/// The in-app notifications: what the background watch announces while the
/// hub window is focused (the OS toast is for an unfocused or hidden window).
///
/// They are overlays in the toast stack at the bottom of the window, never
/// part of the page layout, so nothing shifts when one appears. Each notice is
/// a live region, so a screen reader announces it when it appears, and it
/// never takes focus. It stays until the user dismisses it with the visible
/// button; it does not expire on a timer and does not animate.
class NoticeBanners extends StatelessWidget {
  const NoticeBanners({
    super.key,
    required this.notices,
    required this.onDismiss,
  });

  final List<HubNotice> notices;
  final void Function(int id) onDismiss;

  @override
  Widget build(BuildContext context) {
    if (notices.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final notice in notices)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              key: ValueKey('notice-${notice.id}'),
              liveRegion: true,
              container: true,
              child: PhysicalModel(
                color: Colors.transparent,
                elevation: 8,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  // InfoBar is translucent; give it an opaque base.
                  child: ColoredBox(
                    color: DynTokens.of(context).card,
                    child: InfoBar(
                      isLong: true,
                      style: hubInfoBarStyle(context),
                      title: Text(notice.title),
                      content: Text(notice.message),
                      action: ClickButton(
                        onPressed: () => onDismiss(notice.id),
                        child: Text(context.l10n.dismissNotification),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
