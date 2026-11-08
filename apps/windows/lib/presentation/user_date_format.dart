import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';

/// Formats a catalog date (`YYYY-MM-DD`) as the short date the user chose in
/// Windows' region settings (Settings > Time & language > Region), e.g.
/// `06.11.2026` or `11/6/2026`.
///
/// Read live through `GetDateFormatEx`, so a changed setting shows on the
/// next rebuild. Text that is not a calendar date is returned unchanged, and
/// off Windows (tests, previews) the ISO date is kept.
String formatUserDate(String isoDate) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(isoDate);
  if (match == null || !Platform.isWindows) return isoDate;
  final formatted = _windowsShortDate(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
  return formatted ?? isoDate;
}

final class _SystemTime extends Struct {
  @Uint16()
  external int year, month, dayOfWeek, day, hour, minute, second, millis;
}

typedef _GetDateFormatExNative = Int32 Function(
  Pointer<Utf16>,
  Uint32,
  Pointer<_SystemTime>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Int32,
  Pointer<Utf16>,
);
typedef _GetDateFormatExDart = int Function(
  Pointer<Utf16>,
  int,
  Pointer<_SystemTime>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  int,
  Pointer<Utf16>,
);

final _getDateFormatEx = DynamicLibrary.open('kernel32.dll')
    .lookupFunction<_GetDateFormatExNative, _GetDateFormatExDart>(
      'GetDateFormatEx',
    );

const _dateShortDate = 0x1;
const _bufferLength = 80;

String? _windowsShortDate(int year, int month, int day) {
  final time = calloc<_SystemTime>();
  final buffer = calloc<Uint16>(_bufferLength).cast<Utf16>();
  try {
    time.ref
      ..year = year
      ..month = month
      ..day = day;
    // A null locale name is LOCALE_NAME_USER_DEFAULT: the user's own
    // format, including any customised short date pattern.
    final written = _getDateFormatEx(
      nullptr,
      _dateShortDate,
      time,
      nullptr,
      buffer,
      _bufferLength,
      nullptr,
    );
    // 0 means the date was rejected (e.g. day 31 in a 30-day month).
    return written == 0 ? null : buffer.toDartString();
  } finally {
    calloc.free(time);
    calloc.free(buffer);
  }
}
