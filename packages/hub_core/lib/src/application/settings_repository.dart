import '../domain/app_settings.dart';

/// Port: persistence of the launcher's own preferences.
abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
