import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers a mock handler for the `window_manager` platform channel so
/// widget tests can pump widgets that talk to the native window (caption
/// button state probes and window title sync) without a running app process.
void mockWindowManagerChannel() {
  const channel = MethodChannel('window_manager');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        return switch (call.method) {
          'isMaximized' || 'isMinimized' || 'isPreventClose' => false,
          'isVisible' || 'isFocused' => true,
          _ => null,
        };
      });
}
