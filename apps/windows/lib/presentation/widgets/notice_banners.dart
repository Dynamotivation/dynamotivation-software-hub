import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../controllers/hub_controller.dart';
import '../theme/dynamotivation_theme.dart';

/// The in-app notifications: what the background watch announces while the
/// hub window is focused (the OS toast is for an unfocused or hidden window).
///
/// Each notice is a live region, so a screen reader announces it when it
/// appears, and it never takes focus. It stays until the user dismisses it
/// with the visible button; it does not expire on a timer and does not
/// animate.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          for (final notice in notices)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Semantics(
                key: ValueKey('notice-${notice.id}'),
                liveRegion: true,
                container: true,
                child: ColoredBox(
                  // InfoBar is translucent; give it an opaque base.
                  color: DynTokens.of(context).card,
                  child: InfoBar(
                    isLong: true,
                    title: Text(notice.title),
                    content: Text(notice.message),
                    action: Button(
                      onPressed: () => onDismiss(notice.id),
                      child: Text(context.l10n.dismissNotification),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
