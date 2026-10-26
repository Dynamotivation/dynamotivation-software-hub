import '../application/settings_repository.dart';
import '../domain/app_settings.dart';

/// Non-persistent settings store, used until file-backed preferences exist.
class InMemorySettingsRepository implements SettingsRepository {
  AppSettings _settings;

  InMemorySettingsRepository([this._settings = const AppSettings()]);

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}
