import 'package:fluent_ui/fluent_ui.dart';

import '../models/settings_model.dart';
import '../theme/dynamotivation_theme.dart';

class SettingsView extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onBack;
  final ValueChanged<String> onRegisterPackage;
  final VoidCallback onRefreshCatalog;

  const SettingsView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBack,
    required this.onRegisterPackage,
    required this.onRefreshCatalog,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _packageController = TextEditingController();

  @override
  void dispose() {
    _packageController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    final text = _packageController.text.trim();
    if (text.isNotEmpty) {
      widget.onRegisterPackage(text);
      _packageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings Header with Back button
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(FluentIcons.chevron_left, size: 16),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DynTokens.dark.text : DynTokens.light.text,
                ),
              ),
            ],
          ),
        ),

        // Settings scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              // Appearance Card
              _SettingsCard(
                title: 'Appearance',
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeOptionTile(
                        title: 'System',
                        subtitle: 'Matches OS mode',
                        isSelected:
                            widget.settings.themeMode == AppThemeMode.system,
                        onTap: () {
                          widget.onSettingsChanged(
                            widget.settings.copyWith(
                              themeMode: AppThemeMode.system,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ThemeOptionTile(
                        title: 'Light',
                        subtitle: 'Vibrant coral',
                        isSelected:
                            widget.settings.themeMode == AppThemeMode.light,
                        onTap: () {
                          widget.onSettingsChanged(
                            widget.settings.copyWith(
                              themeMode: AppThemeMode.light,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ThemeOptionTile(
                        title: 'Dark',
                        subtitle: 'Deep maroon & charcoal',
                        isSelected:
                            widget.settings.themeMode == AppThemeMode.dark,
                        onTap: () {
                          widget.onSettingsChanged(
                            widget.settings.copyWith(
                              themeMode: AppThemeMode.dark,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // System Integration Card
              _SettingsCard(
                title: 'System Integration',
                child: Column(
                  children: [
                    _ToggleRow(
                      title: 'Autostart in background',
                      description:
                          'Start the Software Hub silently when you log in',
                      value: widget.settings.autostartInBackground,
                      onChanged: (val) {
                        widget.onSettingsChanged(
                          widget.settings.copyWith(autostartInBackground: val),
                        );
                      },
                    ),
                    const _CardDivider(),
                    _ToggleRow(
                      title: 'Keep running in background',
                      description:
                          'Stay in the system tray when the window is closed',
                      value: widget.settings.keepRunningInBackground,
                      onChanged: (val) {
                        widget.onSettingsChanged(
                          widget.settings.copyWith(
                            keepRunningInBackground: val,
                          ),
                        );
                      },
                    ),
                    const _CardDivider(),
                    _ToggleRow(
                      title: 'Automatically check for updates',
                      description: 'Periodically check whether installed software or the Hub has a newer version',
                      value: widget.settings.autoCheckUpdates,
                      onChanged: (val) {
                        widget.onSettingsChanged(
                          widget.settings.copyWith(autoCheckUpdates: val),
                        );
                      },
                    ),
                    const _CardDivider(),
                    _ToggleRow(
                      title: 'Show notifications',
                      description:
                          'Notify me when updates or downloads complete',
                      value: widget.settings.showNotifications,
                      onChanged: (val) {
                        widget.onSettingsChanged(
                          widget.settings.copyWith(showNotifications: val),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Software Registration Card
              _SettingsCard(
                title: 'Software Registration',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register custom software packages or manually trigger a catalog sync.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? DynTokens.dark.textMuted
                            : DynTokens.light.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextBox(
                            controller: _packageController,
                            placeholder: 'Software name...',
                            onSubmitted: (_) => _submitRegistration(),
                            decoration: WidgetStateProperty.all(
                              BoxDecoration(
                                color: isDark
                                    ? const Color(0x28FFFFFF)
                                    : const Color(0xF2FFFFFF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0x2EFFFFFF)
                                      : const Color(0x2A000000),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _submitRegistration,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 3,
                            ),
                            child: Text('Register'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Button(
                          onPressed: widget.onRefreshCatalog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(FluentIcons.refresh, size: 12),
                                SizedBox(width: 6),
                                Text('Refresh catalog'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? DynTokens.dark.card : DynTokens.light.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? DynTokens.dark.cardBorder
              : DynTokens.light.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? DynTokens.dark.text : DynTokens.light.text,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;

    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        final isHover = states.isHovered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? DynamotivationTheme.coralPrimary.withValues(alpha: 0.16)
                      : DynamotivationTheme.coralPrimary.withValues(
                          alpha: 0.08,
                        ))
                : (isHover
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03))
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? DynamotivationTheme.coralPrimary
                  : (isHover
                        ? (isDark
                              ? const Color(0x33FFFFFF)
                              : const Color(0x33000000))
                        : (isDark
                              ? DynTokens.dark.cardBorder
                              : DynTokens.light.cardBorder)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DynTokens.dark.text : DynTokens.light.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark
                      ? DynTokens.dark.textMuted
                      : DynTokens.light.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
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
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? DynTokens.dark.text : DynTokens.light.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? DynTokens.dark.textMuted
                        : DynTokens.light.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ToggleSwitch(
            checked: value,
            onChanged: onChanged,
            style: ToggleSwitchThemeData(
              checkedDecoration: WidgetStateProperty.all(
                BoxDecoration(
                  color: DynamotivationTheme.coralPrimary,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;
    return Divider(
      style: DividerThemeData(
        thickness: 1,
        decoration: BoxDecoration(
          color: isDark ? const Color(0x14FFFFFF) : const Color(0x14000000),
        ),
      ),
    );
  }
}
