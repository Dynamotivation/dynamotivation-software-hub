import 'package:pub_semver/pub_semver.dart';

/// Unknown/nonstandard versions never imply an available update. Accept the
/// website's two-part versions and Windows' four-part numeric versions too.
bool isNewerSoftwareVersion(String candidate, String installed) {
  final next = _parse(candidate);
  final current = _parse(installed);
  if (next == null || current == null) return false;
  final order = next.$1.compareTo(current.$1);
  return order > 0 || (order == 0 && next.$2 > current.$2);
}

(Version, int)? _parse(String value) {
  final match = RegExp(
    r'^[vV]?(\d+)\.(\d+)(?:\.(\d+))?(?:\.(\d+))?(-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  try {
    return (
      Version.parse(
        '${match[1]}.${match[2]}.${match[3] ?? '0'}${match[5] ?? ''}',
      ),
      int.parse(match[4] ?? '0'),
    );
  } on FormatException {
    return null;
  }
}
