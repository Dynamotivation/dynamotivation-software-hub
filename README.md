# Dynamotivation Software Hub

Desktop launcher and toolbox for Dynamotivation software installed on your device. Built with Flutter and [fluent_ui](https://pub.dev/packages/fluent_ui) (Windows, Mica backdrop).

## Develop
```sh
cd apps/flutter
flutter pub get
flutter run -d windows   # add `-- --dark` / `-- --settings` to preview
flutter analyze
flutter test
```

## Release (local)
```sh
cd apps/flutter
flutter build windows
```

See [AGENTS.md](AGENTS.md) for project conventions and `apps/flutter/README.md` for localization.
