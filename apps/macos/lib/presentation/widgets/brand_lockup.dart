import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hub_l10n/hub_l10n.dart';
import 'package:macos_ui/macos_ui.dart';

/// Dynamotivation logo with the product name, shown at the top of the sidebar.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final l10n = context.l10n;
    final logo = theme.brightness.isDark
        ? 'assets/dynamotivation-logo-dark.svg'
        : 'assets/dynamotivation-logo.svg';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          SvgPicture.asset(logo, width: 34, height: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.brandName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption1,
                ),
                Text(
                  l10n.productName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.title3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
