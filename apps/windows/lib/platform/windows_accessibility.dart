import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Windows' actual contrast palette; independent of the app's light/dark choice.
@immutable
class WindowsContrastPalette {
  final bool enabled;
  final Color window,
      text,
      button,
      buttonText,
      highlight,
      highlightText,
      disabled;

  const WindowsContrastPalette({
    required this.enabled,
    required this.window,
    required this.text,
    required this.button,
    required this.buttonText,
    required this.highlight,
    required this.highlightText,
    required this.disabled,
  });

  factory WindowsContrastPalette.fromMap(Map<Object?, Object?> map) =>
      WindowsContrastPalette(
        enabled: map['enabled'] as bool,
        window: Color(map['window'] as int),
        text: Color(map['text'] as int),
        button: Color(map['button'] as int),
        buttonText: Color(map['buttonText'] as int),
        highlight: Color(map['highlight'] as int),
        highlightText: Color(map['highlightText'] as int),
        disabled: Color(map['disabled'] as int),
      );
}

/// Composed in main; native broadcasts keep the palette current without polling.
class WindowsAccessibility extends ValueNotifier<WindowsContrastPalette?> {
  static const channel = MethodChannel('dynamotivation/windows_accessibility');
  bool _disposed = false;
  int _generation = 0;

  /// True while the taskbar (and so the tray) is light, false while dark;
  /// null until read. This is Windows' "Windows mode", which can differ from
  /// the apps' theme. Kept current by the same native broadcasts as the
  /// contrast palette.
  final ValueNotifier<bool?> taskbarLight = ValueNotifier<bool?>(null);

  WindowsAccessibility() : super(null);

  /// Single MSAA alert: Flutter's dual MSAA/UIA announce path repeats speech
  /// in Narrator, while its legacy switch state-change event is silent.
  static Future<void> announceSwitch(String message) async {
    try {
      await channel.invokeMethod<void>('announceSwitch', message);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Windows accessibility',
          context: ErrorDescription('while announcing a switch state change'),
        ),
      );
    }
  }

  Future<void> initialize() async {
    channel.setMethodCallHandler((call) async {
      if (call.method != 'changed') return;
      try {
        await refresh();
        await refreshTaskbarTheme();
      } catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
    });
    await refresh();
    await refreshTaskbarTheme();
  }

  Future<void> refreshTaskbarTheme() async {
    final light = await channel.invokeMethod<bool>('readTaskbarTheme');
    if (!_disposed && light != null) taskbarLight.value = light;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await channel.invokeMapMethod<Object?, Object?>(
      'readContrast',
    );
    if (result == null) {
      throw StateError('Windows returned no contrast settings');
    }
    final palette = WindowsContrastPalette.fromMap(result);
    if (!_disposed && generation == _generation) value = palette;
  }

  @override
  void dispose() {
    _disposed = true;
    taskbarLight.dispose();
    channel.setMethodCallHandler(null);
    super.dispose();
  }
}

class WindowsContrastScope extends InheritedWidget {
  final WindowsContrastPalette? palette;
  const WindowsContrastScope({
    super.key,
    required this.palette,
    required super.child,
  });

  static WindowsContrastPalette? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<WindowsContrastScope>()
      ?.palette;

  @override
  bool updateShouldNotify(WindowsContrastScope oldWidget) =>
      palette != oldWidget.palette;
}
