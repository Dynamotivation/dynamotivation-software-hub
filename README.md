# Dynamotivation Software Hub

Desktop launcher and toolbox for Dynamotivation software installed on your device. Flutter monorepo with one frontend per OS on top of a shared core.

```
packages/hub_core   pure Dart: domain, application, infrastructure
packages/hub_l10n   shared ARB translations (Crowdin-compatible)
apps/windows        Fluent UI frontend (Mica)
```

## Develop
```sh
flutter pub get                  # once, at the repo root (Dart workspace)
cd apps/windows && flutter run -d windows
```
Checks (run in each package you touched): `flutter analyze`, `flutter test`.

## Release (local)
```sh
cd apps/windows && flutter build windows
```

See [AGENTS.md](AGENTS.md) for conventions.
