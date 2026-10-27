/// Display form of a version: `v1.2.3`, or nothing when the catalog has no
/// version (the website publishes none for most packages).
String versionLabel(String version) => version.isEmpty ? '' : 'v$version';
