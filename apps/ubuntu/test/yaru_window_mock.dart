import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers mock handlers for the `yaru_window` platform channels so widget
/// tests can pump widgets that talk to the native window (title bar state and
/// window controls) without a real platform implementation.
void mockYaruWindowChannel() {
  const channel = MethodChannel('yaru_window');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        // A single active, normal (not maximized) window supporting
        // minimize/maximize/close, as `state` answers with a state map.
        return switch (call.method) {
          'state' => {
            'active': true,
            'closable': true,
            'minimizable': true,
            'maximizable': true,
            'restorable': false,
            'movable': true,
            'visible': true,
          },
          _ => null,
        };
      });

  // The state broadcast stream of the window title bar. The EventChannel's
  // broadcast stream invokes `listen`/`cancel` on a method channel that
  // carries the same name, so register it as a method channel mock.
  const events = MethodChannel('yaru_window/events');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(events, (call) async => null);
}
