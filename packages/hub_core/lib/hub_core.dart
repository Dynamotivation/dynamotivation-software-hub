/// Platform-independent core of the Software Hub. Every frontend (Windows,
/// macOS, Linux, ...) depends on this library and on nothing below `src/`.
library;

export 'src/application/errors.dart';
export 'src/application/hub_use_cases.dart';
export 'src/application/package_repository.dart';
export 'src/application/settings_repository.dart';
export 'src/domain/app_settings.dart';
export 'src/domain/software_package.dart';
export 'src/infrastructure/in_memory_package_repository.dart';
export 'src/infrastructure/in_memory_settings_repository.dart';
export 'src/infrastructure/website_package_repository.dart';
