import '../user_date_format.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../errors.dart';
import '../theme/dynamotivation_theme.dart';

/// Choose a release of [name] to install. Loads the choices itself (the
/// release history may need fetching first) and returns the chosen version,
/// or null when cancelled. Releases without a download for this device and
/// the installed one stay listed but cannot be chosen.
class VersionPickerDialog extends StatefulWidget {
  final String name;
  final Future<List<ReleaseChoice>> Function() load;

  const VersionPickerDialog({
    super.key,
    required this.name,
    required this.load,
  });

  @override
  State<VersionPickerDialog> createState() => _VersionPickerDialogState();
}

class _VersionPickerDialogState extends State<VersionPickerDialog> {
  late Future<List<ReleaseChoice>> _choices = widget.load();
  String? _chosen;

  void _retry() => setState(() => _choices = widget.load());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ContentDialog(
      title: Text(l10n.installVersionTitle(widget.name)),
      constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
      content: FutureBuilder<List<ReleaseChoice>>(
        future: _choices,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(describeError(l10n, snapshot.error!)),
                const SizedBox(height: 12),
                Button(onPressed: _retry, child: Text(l10n.retry)),
              ],
            );
          }
          final choices = snapshot.data;
          if (choices == null) {
            return Semantics(
              label: l10n.loadingVersions,
              child: const Center(child: ProgressRing()),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.installVersionBody),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: RadioGroup<String>(
                    groupValue: _chosen,
                    onChanged: (version) => setState(() => _chosen = version),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final choice in choices) _row(context, choice),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        Button(
          autofocus: true,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _chosen == null
              ? null
              : () => Navigator.pop(context, _chosen),
          child: Text(l10n.installAction),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, ReleaseChoice choice) {
    final l10n = context.l10n;
    final tokens = DynTokens.of(context);
    final notes = [
      if (choice.isLatest) l10n.versionLatest,
      if (choice.isInstalled) l10n.versionInstalled,
      if (!choice.installable) l10n.versionNoDownload,
    ];
    final label = [
      'v${choice.version}',
      if (choice.date.isNotEmpty) formatUserDate(choice.date),
      ...notes,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RadioButton<String>(
        value: choice.version,
        enabled: choice.selectable,
        content: Text(
          label,
          style: choice.selectable ? null : TextStyle(color: tokens.textMuted),
        ),
      ),
    );
  }
}
