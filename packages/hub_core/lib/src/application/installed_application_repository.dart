import '../domain/installed_application.dart';

/// Port for installed applications in the publisher's scope on this device.
/// An empty list means none are installed; a failed scan must throw.
abstract interface class InstalledApplicationRepository {
  Future<List<InstalledApplication>> scan();
}
