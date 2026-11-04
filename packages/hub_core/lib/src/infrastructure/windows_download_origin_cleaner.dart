import 'dart:io';

import '../application/download_origin_cleaner.dart';

/// Deletes only the Windows Internet-zone alternate data stream.
/// Filesystem failures propagate to the caller and must prevent launch.
class WindowsDownloadOriginCleaner implements DownloadOriginCleaner {
  const WindowsDownloadOriginCleaner();

  @override
  Future<void> clear(String path) async {
    if (!Platform.isWindows) return;
    // Require the base file to exist even when the stream is absent.
    await File(path).length();
    try {
      await File('$path:Zone.Identifier').delete();
    } on FileSystemException catch (error) {
      // ERROR_FILE_NOT_FOUND only; access denied and missing directories fail.
      if (error.osError?.errorCode != 2) rethrow;
    }
  }
}
