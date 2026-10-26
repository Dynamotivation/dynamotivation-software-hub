# hub_l10n

UI strings shared by every Software Hub frontend. ARB files in `lib/l10n/`
(Flutter `gen-l10n`; the format Crowdin imports natively). `app_en.arb` is the
template/source; other locales are `app_<locale>.arb`. Frontends import
`package:hub_l10n/hub_l10n.dart` and read strings via `context.l10n.<key>`.

- Add or change a string: edit `app_en.arb` (with an `@key` description and
  `placeholders` where needed), then run `flutter gen-l10n` in this package.
  Generated Dart files are committed.
- Translations: `crowdin.yml` at the repo root maps `app_en.arb` to
  `app_%two_letters_code%.arb`. Set `CROWDIN_PROJECT_ID` and
  `CROWDIN_PERSONAL_TOKEN`, then `crowdin upload sources` / `crowdin download`.
- A new locale needs only its `app_<locale>.arb`; `test/l10n_test.dart` checks
  key parity.
- Package catalog content (names, descriptions, release notes) is catalog data,
  not UI chrome, and is not part of the ARB files.
