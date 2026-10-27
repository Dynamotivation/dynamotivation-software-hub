import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_scroll/hub_scroll.dart';
import 'package:macos_ui/macos_ui.dart';

import '../theme/dynamotivation_macos_theme.dart';

/// Preferences, shown in the content area. (macOS convention is a separate
/// Settings window opened with Cmd+,; a second Flutter window needs a
/// multi-window plugin, so this is a non-modal in-window pane for now.)
class SettingsView extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  /// Space reserved at the top for the floating toolbar.
  final double topInset;

  const SettingsView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.topInset,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _scroll = ScrollController();

  AppSettings get _s => widget.settings;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// A System Settings style row: title and optional subtitle on the left,
  /// control on the right.
  Widget _row(
    BuildContext context,
    String title,
    Widget control, {
    String? subtitle,
  }) {
    final typography = MacosTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.body),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: typography.caption1.copyWith(
                      color: typography.caption1.color?.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }

  Widget _toggle(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    AppSettings Function(bool) apply,
  ) => _row(
    context,
    title,
    MacosSwitch(
      value: value,
      onChanged: (v) => widget.onSettingsChanged(apply(v)),
    ),
    subtitle: subtitle,
  );

  /// Grouped inset list: secondary heading above a rounded card whose rows
  /// are separated by hairlines.
  Widget _group(
    BuildContext context,
    String heading,
    List<Widget> rows, {
    String? footer,
  }) {
    final theme = MacosTheme.of(context);
    final isDark = theme.brightness.isDark;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Container(height: 1, color: theme.dividerColor),
          ),
        );
      }
      children.add(rows[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 6),
            child: Text(
              heading,
              style: theme.typography.subheadline.copyWith(
                color: theme.typography.subheadline.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0x0FFFFFFF) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              // High contrast: a hard edge instead of the faint hairline.
              border: Border.all(
                color: MediaQuery.highContrastOf(context)
                    ? DynBrand.hardContrast(isDark)
                    : theme.dividerColor,
              ),
            ),
            child: Column(children: children),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Text(footer, style: theme.typography.caption1),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = MacosTheme.of(context).typography;

    return SmoothScroll(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        physics: smoothScrollPhysics,
        padding: EdgeInsets.fromLTRB(32, widget.topInset, 32, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14, bottom: 18),
                  child: Text(l10n.settings, style: typography.largeTitle),
                ),
                _group(context, l10n.appearance, [
                  _row(
                    context,
                    l10n.appearance,
                    MacosPopupButton<AppThemeMode>(
                      value: _s.themeMode,
                      onChanged: (m) {
                        if (m != null) {
                          widget.onSettingsChanged(_s.copyWith(themeMode: m));
                        }
                      },
                      items: [
                        MacosPopupMenuItem(
                          value: AppThemeMode.system,
                          child: Text(l10n.themeSystem),
                        ),
                        MacosPopupMenuItem(
                          value: AppThemeMode.light,
                          child: Text(l10n.themeLight),
                        ),
                        MacosPopupMenuItem(
                          value: AppThemeMode.dark,
                          child: Text(l10n.themeDark),
                        ),
                      ],
                    ),
                  ),
                ]),
                _group(context, l10n.systemIntegration, [
                  _toggle(
                    context,
                    l10n.autostartTitle,
                    l10n.autostartDescription,
                    _s.autostartInBackground,
                    (v) => _s.copyWith(autostartInBackground: v),
                  ),
                  _toggle(
                    context,
                    l10n.keepRunningTitle,
                    l10n.keepRunningDescription,
                    _s.keepRunningInBackground,
                    (v) => _s.copyWith(keepRunningInBackground: v),
                  ),
                  _toggle(
                    context,
                    l10n.autoCheckTitle,
                    l10n.autoCheckDescription,
                    _s.autoCheckUpdates,
                    (v) => _s.copyWith(autoCheckUpdates: v),
                  ),
                  _toggle(
                    context,
                    l10n.notificationsTitle,
                    l10n.notificationsDescription,
                    _s.showNotifications,
                    (v) => _s.copyWith(showNotifications: v),
                  ),
                ]),
                // About, mirroring the Windows and Ubuntu frontends: product
                // name over the verified publisher row.
                _group(context, l10n.settingsAboutHeading, [
                  _row(
                    context,
                    l10n.productName,
                    const SizedBox.shrink(),
                    subtitle: l10n.brandName,
                  ),
                  _row(
                    context,
                    l10n.publisher,
                    MacosIcon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 16,
                      color: DynBrand.accent,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
