import 'package:fluent_ui/fluent_ui.dart';

import 'package:hub_l10n/hub_l10n.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_scroll/hub_scroll.dart';

import '../theme/dynamotivation_theme.dart';
import 'accessible_icon_button.dart';
import 'accessible_switch.dart';
import 'click_cursor.dart';

/// Settings in the style of the Windows 11 Settings app: a page title, then
/// cards whose rows pair a title and description with a control on the right.
class SettingsView extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onBack;
  final FocusNode? backFocusNode;

  const SettingsView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBack,
    this.backFocusNode,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late final FocusNode _appearanceFocus = FocusNode(debugLabel: 'Appearance')
    ..addListener(_appearanceFocusChanged);
  void _appearanceFocusChanged() => setState(() {});
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.isDismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _appearanceFocus.removeListener(_appearanceFocusChanged);
    _appearanceFocus.dispose();
    _entrance.dispose();
    super.dispose();
  }

  // A fixed logical-pixel offset keeps the entrance subtle at every window size.
  Widget _enter(Widget child, {double delay = 0}) {
    final progress = _entrance.drive(
      CurveTween(curve: Interval(delay, 1, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: progress,
      child: AnimatedBuilder(
        animation: progress,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 16 * (1 - progress.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final onSettingsChanged = widget.onSettingsChanged;
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
        _enter(
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
            child: Row(
              children: [
                AccessibleIconButton(
                  label: l10n.backToSoftware,
                  icon: const Icon(FluentIcons.chevron_left, size: 16),
                  focusNode: widget.backFocusNode,
                  onPressed: widget.onBack,
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
        ),
        Expanded(
          child: _enter(
            _SmoothSettingsList(
              children: [
                _Card(
                  children: [
                    // The combobox node itself only carries the current value
                    // ("Light"), so the row is merged: the reader gets
                    // "Appearance" together with the value, not the value
                    // alone ("Light, button").
                    MergeSemantics(
                      child: Semantics(
                        container: true,
                        focusable: true,
                        focused: _appearanceFocus.hasFocus,
                        child: _SettingRow(
                          title: l10n.appearance,
                          control: SizedBox(
                            width: 180,
                            child: ClickCursor(
                              child: ComboBox<AppThemeMode>(
                                focusNode: _appearanceFocus,
                                isExpanded: true,
                                value: settings.themeMode,
                                // ComboBox already supplies the selected value as
                                // its semantic label. Keep the painted copy from
                                // repeating it in the merged row announcement.
                                selectedItemBuilder: (context) => [
                                  for (final mode in AppThemeMode.values)
                                    ExcludeSemantics(
                                      child: Text(themeName(mode)),
                                    ),
                                ],
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
            delay: 0.125,
          ),
        ),
      ],
    );
  }
}

/// Scrollable column of settings cards with the eased mouse-wheel scrolling
/// every scroll view in the app uses.
class _SmoothSettingsList extends StatefulWidget {
  final List<Widget> children;

  const _SmoothSettingsList({required this.children});

  @override
  State<_SmoothSettingsList> createState() => _SmoothSettingsListState();
}

class _SmoothSettingsListState extends State<_SmoothSettingsList> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmoothScroll(
      controller: _scroll,
      child: ListView(
        controller: _scroll,
        physics: smoothScrollPhysics,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        children: widget.children,
      ),
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
  final bool controlLabelsRow;

  const _SettingRow({
    required this.title,
    required this.control,
    this.description,
    this.controlLabelsRow = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DynTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: ExcludeSemantics(
              excluding: controlLabelsRow,
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
      controlLabelsRow: true,
      control: AccessibleSwitch(
        value: value,
        onChanged: onChanged,
        label: title,
        description: description,
      ),
    );
  }
}
