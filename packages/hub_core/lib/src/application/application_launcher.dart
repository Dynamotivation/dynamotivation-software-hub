/// OS port for starting an installed application's executable without a shell.
abstract interface class ApplicationLauncher {
  Future<void> launch(String executable);
}
