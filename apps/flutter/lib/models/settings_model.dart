enum AppThemeMode { system, light, dark }

class AppSettings {
  final AppThemeMode themeMode;
  final bool autostartInBackground;
  final bool keepRunningInBackground;
  final bool autoCheckUpdates;
  final bool showNotifications;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.autostartInBackground = false,
    this.keepRunningInBackground = true,
    this.autoCheckUpdates = true,
    this.showNotifications = true,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? autostartInBackground,
    bool? keepRunningInBackground,
    bool? autoCheckUpdates,
    bool? showNotifications,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      autostartInBackground:
          autostartInBackground ?? this.autostartInBackground,
      keepRunningInBackground:
          keepRunningInBackground ?? this.keepRunningInBackground,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      showNotifications: showNotifications ?? this.showNotifications,
    );
  }
}
