import 'package:fluent_ui/fluent_ui.dart';

import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_core/hub_core.dart';

import '../theme/dynamotivation_theme.dart';

/// Settings in the style of the Windows 11 Settings app: a page title, then
/// cards whose rows pair a title and description with a control on the right.
class SettingsView extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onBack;

  const SettingsView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = DynTokens.of(context);

    String themeName(AppThemeMode mode) => switch (mode) {
      AppThemeMode.system => l10n.themeSystem,
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
          child: Row(
            children: [
              Tooltip(
                message: l10n.backToSoftware,
                child: IconButton(
                  icon: const Icon(FluentIcons.chevron_left, size: 16),
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                header: true,
                child: Text(
                  l10n.settings,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: tokens.text,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            children: [
              _Card(
                children: [
                  _SettingRow(
                    title: l10n.appearance,
                    control: SizedBox(
                      width: 180,
                      child: ComboBox<AppThemeMode>(
                        isExpanded: true,
                        value: settings.themeMode,
                        items: [
                          for (final mode in AppThemeMode.values)
                            ComboBoxItem(
                              value: mode,
                              child: Text(themeName(mode)),
                            ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) {
                            onSettingsChanged(
                              settings.copyWith(themeMode: mode),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.systemIntegration,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.text,
                    ),
                  ),
                ),
              ),
              _Card(
                children: [
                  _ToggleRow(
                    title: l10n.autostartTitle,
                    description: l10n.autostartDescription,
                    value: settings.autostartInBackground,
                    onChanged: (v) => onSettingsChanged(
                      settings.copyWith(autostartInBackground: v),
                    ),
                  ),
                  _ToggleRow(
                    title: l10n.keepRunningTitle,
                    description: l10n.keepRunningDescription,
                    value: settings.keepRunningInBackground,
                    onChanged: (v) => onSettingsChanged(
                      settings.copyWith(keepRunningInBackground: v),
                    ),
                  ),
                  _ToggleRow(
                    title: l10n.autoCheckTitle,
                    description: l10n.autoCheckDescription,
                    value: settings.autoCheckUpdates,
                    onChanged: (v) => onSettingsChanged(
                      settings.copyWith(autoCheckUpdates: v),
                    ),
                  ),
                  _ToggleRow(
                    title: l10n.notificationsTitle,
                    description: l10n.notificationsDescription,
                    value: settings.showNotifications,
                    onChanged: (v) => onSettingsChanged(
                      settings.copyWith(showNotifications: v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

/// One card holding one or more rows, separated by hairlines.
class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: tokens.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String? description;
  final Widget control;

  const _SettingRow({
    required this.title,
    required this.control,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: tokens.text,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: TextStyle(fontSize: 12, color: tokens.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      title: title,
      description: description,
      control: ToggleSwitch(
        checked: value,
        onChanged: onChanged,
        semanticLabel: title,
        style: ToggleSwitchThemeData(
          checkedDecoration: WidgetStateProperty.all(
            BoxDecoration(
              color: DynamotivationTheme.coralPrimary,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
    );
  }
}
