import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Painted macOS traffic lights, for design previews on other platforms
/// (`--mac-chrome`). On a real Mac the system draws these.
class MacWindowControlsPreview extends StatelessWidget {
  const MacWindowControlsPreview({super.key});

  static const _colors = [
    Color(0xFFFF5F57),
    Color(0xFFFEBC2E),
    Color(0xFF28C840),
  ];
  static const _labels = ['Close', 'Minimize', 'Zoom'];

  static Future<void> _maximizeToggle() async =>
      await windowManager.isMaximized()
      ? windowManager.unmaximize()
      : windowManager.maximize();

  static void _act(int i) => switch (i) {
    0 => windowManager.close(),
    1 => windowManager.minimize(),
    _ => _maximizeToggle(),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _colors.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              label: _labels[i],
              excludeSemantics: true,
              onTap: () => _act(i),
              child: GestureDetector(
                onTap: () => _act(i),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x26000000)),
                    ),
                    child: const SizedBox(width: 12, height: 12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
