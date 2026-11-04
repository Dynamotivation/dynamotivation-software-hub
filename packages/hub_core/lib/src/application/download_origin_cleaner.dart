/// Removes download-origin metadata from a file whose digest was verified.
abstract interface class DownloadOriginCleaner {
  Future<void> clear(String path);
}

/// The verifier must throw on a missing/mismatched SHA-256. Call for both fresh
/// and reused staged setups, at their final path, before launching them.
Future<void> prepareVerifiedSetup(
  String path, {
  required Future<void> Function(String path) verifySha256,
  required DownloadOriginCleaner originCleaner,
}) async {
  await verifySha256(path);
  await originCleaner.clear(path);
}
