/// Device process state for exact installed executable paths.
abstract interface class ApplicationProcesses {
  Future<Set<String>> runningExecutables(Set<String> executables);
  Future<void> terminateAll(String executable);
}
