# hub_core

Platform-independent core (pure Dart, no Flutter):

```
lib/src/domain          SoftwarePackage aggregate, AppSettings. No I/O.
lib/src/application     HubUseCases, repository ports, typed HubException errors.
lib/src/infrastructure  Port adapters (in-memory today).
```

Frontends import only `package:hub_core/hub_core.dart`. Layering is enforced by
`test/architecture_test.dart`.
