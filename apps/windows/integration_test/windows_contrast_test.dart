import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dynamotivation_software_hub/app.dart';
import 'package:dynamotivation_software_hub/platform/windows_accessibility.dart';
import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';

// Independently read the OS palette and notify only this test window.
// Never enable, disable, or edit the user's contrast theme.
const _windowsProbe = r'''
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class NativeContrastProbe {
  [StructLayout(LayoutKind.Sequential)]
  public struct HighContrast { public uint size; public uint flags; public IntPtr scheme; }
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool SystemParametersInfoW(uint action, uint param, ref HighContrast data, uint flags);
  [DllImport("user32.dll")]
  public static extern uint GetSysColor(int index);
  [DllImport("user32.dll")]
  public static extern IntPtr SendMessageW(IntPtr hwnd, uint message, IntPtr wparam, IntPtr lparam);
}
'@
$contrast = [NativeContrastProbe+HighContrast]::new()
$contrast.size = [System.Runtime.InteropServices.Marshal]::SizeOf($contrast)
if (-not [NativeContrastProbe]::SystemParametersInfoW(0x42, $contrast.size, [ref]$contrast, 0)) { throw 'SPI_GETHIGHCONTRAST failed' }
function Read-Color([int]$index) {
  $bgr = [NativeContrastProbe]::GetSysColor($index)
  return [long](0xFF000000L -bor (($bgr -band 255) -shl 16) -bor ($bgr -band 65280) -bor (($bgr -shr 16) -band 255))
}
$palette = @{ enabled = (($contrast.flags -band 1) -ne 0); window = (Read-Color 5); text = (Read-Color 8); button = (Read-Color 15); buttonText = (Read-Color 18); highlight = (Read-Color 13); highlightText = (Read-Color 14); disabled = (Read-Color 17) }
$targetWindow = [System.Diagnostics.Process]::GetProcessById(APP_PID).MainWindowHandle
if ($targetWindow -eq [IntPtr]::Zero) { throw 'Test window was not found' }
[void][NativeContrastProbe]::SendMessageW($targetWindow, 0x15, [IntPtr]::Zero, [IntPtr]::Zero)
$palette | ConvertTo-Json -Compress
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native Windows colors and settings broadcasts reach the app', (
    tester,
  ) async {
    await windowManager.ensureInitialized();
    final source = WindowsAccessibility();
    await source.initialize();
    final c = HubController(
      HubUseCases(
        InMemoryPackageRepository(testCatalog()),
        InMemorySettingsRepository(),
      ),
    );
    await c.load();
    await tester.pumpWidget(
      DynamotivationApp(controller: c, accessibility: source),
    );
    await tester.pumpAndSettle();
    final updated = Completer<void>();
    void onUpdate() {
      if (!updated.isCompleted) updated.complete();
    }

    source.addListener(onUpdate);
    final result = await tester.runAsync(() async {
      final result = await Process.run('pwsh', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        _windowsProbe.replaceAll('APP_PID', pid.toString()),
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      await updated.future.timeout(const Duration(seconds: 10));
      return result;
    });
    final expected = WindowsContrastPalette.fromMap(
      jsonDecode(result!.stdout.toString()) as Map<String, dynamic>,
    );
    final actual = source.value!;
    expect(actual.enabled, expected.enabled);
    expect(actual.window, expected.window);
    expect(actual.text, expected.text);
    expect(actual.button, expected.button);
    expect(actual.buttonText, expected.buttonText);
    expect(actual.highlight, expected.highlight);
    expect(actual.highlightText, expected.highlightText);
    expect(actual.disabled, expected.disabled);
    source.removeListener(onUpdate);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    source.dispose();
  }, skip: !Platform.isWindows);
}
