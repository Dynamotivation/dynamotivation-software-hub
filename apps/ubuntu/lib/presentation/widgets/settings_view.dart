import 'package:flutter/material.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_scroll/hub_scroll.dart';
import 'package:yaru/yaru.dart';

import '../theme/dynamotivation_ubuntu_theme.dart';

/// Full-pane standalone GNOME-style Settings view.
class SettingsView extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onClose;

  const SettingsView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onClose,
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

  Widget _preferenceGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? DynUbuntuTheme.cardDark
                  : DynUbuntuTheme.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? DynUbuntuTheme.cardBorderDark
                    : DynUbuntuTheme.cardBorderLight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? DynUbuntuTheme.cardBorderDark
                            : DynUbuntuTheme.cardBorderLight,
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferenceRow({
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Scrollbar(
          controller: _scroll,
          child: SmoothScroll(
            controller: _scroll,
            child: ListView(
              controller: _scroll,
              physics: smoothScrollPhysics,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                // Appearance
                _preferenceGroup(
                  context,
                  title: l10n.appearance,
                  children: [
                    _preferenceRow(
                      title: l10n.appearance,
                      subtitle: l10n.appearanceSubtitle,
                      trailing: SegmentedButton<AppThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: AppThemeMode.system,
                            label: Text(l10n.themeSystem),
                          ),
                          ButtonSegment(
                            value: AppThemeMode.light,
                            label: Text(l10n.themeLight),
                          ),
                          ButtonSegment(
                            value: AppThemeMode.dark,
                            label: Text(l10n.themeDark),
                          ),
                        ],
                        selected: {_s.themeMode},
                        onSelectionChanged: (selected) {
                          widget.onSettingsChanged(
                            _s.copyWith(themeMode: selected.first),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Behavior / System Integration
                _preferenceGroup(
                  context,
                  title: l10n.systemIntegration,
                  children: [
                    _preferenceRow(
                      title: l10n.autoCheckTitle,
                      subtitle: l10n.autoCheckDescription,
                      trailing: YaruSwitch(
                        value: _s.autoCheckUpdates,
                        onChanged: (val) {
                          widget.onSettingsChanged(
                            _s.copyWith(autoCheckUpdates: val),
                          );
                        },
                      ),
                    ),
                    _preferenceRow(
                      title: l10n.notificationsTitle,
                      subtitle: l10n.notificationsDescription,
                      trailing: YaruSwitch(
                        value: _s.showNotifications,
                        onChanged: (val) {
                          widget.onSettingsChanged(
                            _s.copyWith(showNotifications: val),
                          );
                        },
                      ),
                    ),
                    _preferenceRow(
                      title: l10n.autostartTitle,
                      subtitle: l10n.autostartDescription,
                      trailing: YaruSwitch(
                        value: _s.autostartInBackground,
                        onChanged: (val) {
                          widget.onSettingsChanged(
                            _s.copyWith(autostartInBackground: val),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // About
                _preferenceGroup(
                  context,
                  title: l10n.settingsAboutHeading,
                  children: [
                    _preferenceRow(
                      title: l10n.productName,
                      subtitle: l10n.settingsVersionLine('0.2.0'),
                      trailing: Text(
                        '0.2.0',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    _preferenceRow(
                      title: l10n.publisher,
                      subtitle: l10n.brandName,
                      trailing: Icon(
                        Icons.verified,
                        size: 18,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
