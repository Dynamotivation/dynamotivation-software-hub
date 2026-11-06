import 'package:flutter/services.dart';
import 'package:hub_core/hub_core.dart';

class WindowsApplicationProcesses implements ApplicationProcesses {
  static const channel = MethodChannel('dynamotivation/application_processes');

  @override
  Future<Set<String>> runningExecutables(Set<String> executables) async =>
      (await channel.invokeListMethod<String>(
                'running',
                executables.toList(),
              ) ??
              const [])
          .toSet();

  @override
  Future<void> terminateAll(String executable) =>
      channel.invokeMethod<void>('terminate', executable);
}
