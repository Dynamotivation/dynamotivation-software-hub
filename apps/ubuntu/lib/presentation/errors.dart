import 'package:hub_core/hub_core.dart';
import 'package:hub_l10n/hub_l10n.dart';

/// User-facing text for an error from the use cases. Typed [HubException]s get
/// their localized message; anything else is shown as-is rather than hidden.
String describeError(AppLocalizations l10n, Object error) => switch (error) {
  PackageNotFound(:final id) => l10n.errorPackageNotFound(id),
  PackageActionRejected() => l10n.errorActionRejected,
  _ => error.toString(),
};
