# Software Hub for Windows

Fluent UI (Mica) frontend. Depends on `hub_core` and `hub_l10n`; contains only
presentation and the composition root.

```
lib/main.dart            composition root: wires adapters, window, Mica
lib/app.dart             FluentApp, theme and localization setup
lib/presentation/        controllers (state), pages, widgets, theme
```

```sh
flutter run -d windows          # from this directory; `-- --dark`, `-- --settings`
flutter build windows
```

A frontend for another OS is a sibling `apps/<os>` package added to the root
`pubspec.yaml` workspace; it reuses the core and strings and brings its own UI.
