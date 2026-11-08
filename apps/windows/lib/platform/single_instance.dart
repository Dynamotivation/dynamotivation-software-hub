import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Keeps the Hub to one process per user.
///
/// The first process creates a named Windows mutex and keeps its handle for as
/// long as it lives; the operating system closes the handle when the process
/// ends, however it ends, so a crash never locks the Hub out. The mutex is
/// only an existence marker (it is never waited on), so no thread owns it.
/// A process that finds the mutex already there is a second launch: it drops a
/// `<name>.show` request file in [directory] and the caller exits. The first
/// process watches for that file and shows its window, so launching the Hub
/// again, from the Start menu or a shortcut, brings the running one forward
/// (also out of the tray) instead of starting a second copy with a second tray
/// icon, update watch and catalog fetches.
///
/// Development builds pass a different [name], so running from source next to
/// the installed Hub does not hand control to the installed one.
///
/// A lock on a file in the cache folder was tried first and dropped: it
/// vanished within seconds of the Hub starting unless something kept using the
/// file handle, while the mutex handle is owned by the OS and cannot.
class SingleInstance {
  SingleInstance._(this.directory, this.name);

  /// An instance that holds no mutex, so tests can exercise the request
  /// signalling on any platform.
  @visibleForTesting
  SingleInstance.withoutMutex(this.directory, {this.name = 'instance'});

  final Directory directory;
  final String name;
  StreamSubscription<FileSystemEvent>? _watch;

  /// The instances of this process, kept reachable until [release] so their
  /// file watch is not collected with them.
  static final Set<SingleInstance> _held = {};

  static File _requestFile(Directory directory, String name) =>
      File('${directory.path}${Platform.pathSeparator}$name.show');

  static String _mutexName(String name) =>
      'Local\\DynamotivationSoftwareHub-$name';

  /// The instance, or null when another process already runs. In that case
  /// that process has been asked to show its window and the caller should
  /// exit. Anywhere but Windows there is nothing to guard and the call always
  /// succeeds.
  static Future<SingleInstance?> acquire(
    Directory directory, {
    String name = 'instance',
  }) async {
    await directory.create(recursive: true);
    if (Platform.isWindows) {
      final mutexName = _mutexName(name).toNativeUtf16();
      try {
        final existing = _Kernel32.openMutex(_synchronize, 0, mutexName);
        if (existing != 0) {
          _Kernel32.closeHandle(existing);
          await requestShow(directory, name: name);
          return null;
        }
        // The handle is deliberately never closed: the process owns it until
        // it ends, and that is the lock.
        _Kernel32.createMutex(nullptr, 0, mutexName);
      } finally {
        calloc.free(mutexName);
      }
    }
    // A request left behind by a process that died is not about this one.
    try {
      await _requestFile(directory, name).delete();
    } on FileSystemException {
      // None there.
    }
    final instance = SingleInstance._(directory, name);
    _held.add(instance);
    return instance;
  }

  /// Asks the running process to show its window.
  static Future<void> requestShow(
    Directory directory, {
    String name = 'instance',
  }) => _requestFile(
    directory,
    name,
  ).writeAsString(DateTime.now().toIso8601String(), flush: true);

  /// Calls [onShow] each time another launch asks for the window. A request
  /// that arrived before this call counts too.
  void listen(void Function() onShow) {
    final request = _requestFile(directory, name);
    // The create event can arrive while the other process still has the file
    // open, and Windows refuses to delete it until it closes it: retry while
    // it is there. Only the call that deletes the file shows the window.
    Future<void> take() async {
      for (var attempt = 0; attempt < 20; attempt++) {
        if (!await request.exists()) return;
        try {
          await request.delete();
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          continue;
        }
        onShow();
        return;
      }
    }

    // By file name: the watcher reports paths in its own spelling.
    final fileName = '$name.show';
    _watch = directory
        .watch()
        .where(
          (event) =>
              event.path.endsWith('/$fileName') ||
              event.path.endsWith('\\$fileName'),
        )
        .listen((_) => take());
    take();
  }

  /// Stops listening. The mutex stays until the process ends.
  Future<void> release() async {
    await _watch?.cancel();
    _watch = null;
    _held.remove(this);
  }
}

const _synchronize = 0x00100000;

/// The few kernel32 calls the guard needs.
class _Kernel32 {
  static final DynamicLibrary _library = DynamicLibrary.open('kernel32.dll');

  static final int Function(int, int, Pointer<Utf16>) openMutex = _library
      .lookupFunction<
        IntPtr Function(Uint32, Int32, Pointer<Utf16>),
        int Function(int, int, Pointer<Utf16>)
      >('OpenMutexW');

  static final int Function(Pointer<Void>, int, Pointer<Utf16>) createMutex =
      _library.lookupFunction<
        IntPtr Function(Pointer<Void>, Int32, Pointer<Utf16>),
        int Function(Pointer<Void>, int, Pointer<Utf16>)
      >('CreateMutexW');

  static final int Function(int) closeHandle = _library
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');
}
