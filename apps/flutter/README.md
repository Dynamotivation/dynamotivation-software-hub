# dynamotivation_software_hub

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Localization

UI strings live in ARB files in `lib/l10n/` (Flutter `gen-l10n`; the format
Crowdin imports natively). `app_en.arb` is the template/source; other locales
are `app_<locale>.arb`. Code reads strings via `context.l10n.<key>`.

- Add or change a string: edit `app_en.arb` (with an `@key` description and
  `placeholders` where needed), then run `flutter gen-l10n`. Generated Dart
  files are committed.
- Translations: `crowdin.yml` at the repo root maps `app_en.arb` to
  `app_%two_letters_code%.arb`. Set `CROWDIN_PROJECT_ID` and
  `CROWDIN_PERSONAL_TOKEN`, then `crowdin upload sources` / `crowdin download`.
- A new locale needs only its `app_<locale>.arb`; it is picked up by
  `AppLocalizations.supportedLocales`. `test/l10n_test.dart` checks key parity.
- Package catalog content (names, descriptions, release notes) is catalog data,
  not UI chrome, and is not part of the ARB files.
