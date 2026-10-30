/// Port: where catalog icons are kept locally.
abstract interface class IconStore {
  /// Makes sure the icon at [url] is stored locally, downloading it if needed.
  /// Completes with false if it could not be fetched; the caller carries on
  /// (a package without an icon is still a package) and the icon's consumer
  /// reports the failure when it tries to read it.
  Future<bool> prefetch(String url);
}
