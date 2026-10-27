import 'dart:ffi';
import 'dart:io' show Platform;

/// Primary language id of the keyboard layout currently active for the UI
/// thread, or null where it cannot be determined (non-Windows).
///
/// Read live on every call (a single cheap Win32 call), so switching layouts
/// with Win+Space is picked up the next time a label is built.
int? activeKeyboardPrimaryLanguage() {
  if (!Platform.isWindows) return null;
  try {
    final getKeyboardLayout = DynamicLibrary.open('user32.dll')
        .lookupFunction<IntPtr Function(Uint32), int Function(int)>(
          'GetKeyboardLayout',
        );
    final hkl = getKeyboardLayout(0); // 0 = calling thread
    return (hkl & 0xFFFF) & 0x3FF; // LANGID -> primary language id
  } catch (_) {
    return null;
  }
}
