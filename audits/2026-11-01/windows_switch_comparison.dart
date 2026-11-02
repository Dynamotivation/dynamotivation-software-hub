// Native diagnostic, not a widget test or production entry point.
// From apps/windows:
// flutter run -d windows -t ../../audits/2026-11-01/windows_switch_comparison.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_l10n/hub_l10n.dart';

import '../../apps/windows/lib/presentation/widgets/accessible_switch.dart';

void main() => runApp(
  FluentApp(
    title: 'Switch reader comparison',
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: FluentThemeData(brightness: Brightness.light),
    home: const _Comparison(),
  ),
);

class _Comparison extends StatefulWidget {
  const _Comparison();

  @override
  State<_Comparison> createState() => _ComparisonState();
}

class _ComparisonState extends State<_Comparison> {
  final _customFocus = FocusNode(debugLabel: 'Custom switch');
  bool _custom = false;
  bool _stock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _customFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _customFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaffoldPage(
    header: const PageHeader(title: Text('Switch reader comparison')),
    content: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tab between controls. Space toggles the focused control.',
          ),
          const SizedBox(height: 24),
          const ExcludeSemantics(child: Text('Custom switch')),
          AccessibleSwitch(
            focusNode: _customFocus,
            label: 'Custom switch',
            value: _custom,
            onChanged: (value) => setState(() => _custom = value),
          ),
          const SizedBox(height: 24),
          ToggleSwitch(
            content: const Text('Stock Fluent switch'),
            checked: _stock,
            onChanged: (value) => setState(() => _stock = value),
          ),
          const SizedBox(height: 24),
          Text('Visual state: custom=$_custom; stock=$_stock'),
        ],
      ),
    ),
  );
}
