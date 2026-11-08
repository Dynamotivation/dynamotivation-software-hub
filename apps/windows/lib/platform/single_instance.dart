import 'dart:async';
import 'dart:io';

/// Keeps the Hub to one process per user.
///
/// The first process holds an exclusive lock on `<name>.lock` in [directory]
/// for as long as it lives; the operating system frees the lock when the
/// process ends, however it ends, so a crash never leaves the Hub locked out.
/// A process that cannot get the lock is a second launch: it drops a
/// `<name>.show` request file beside the lock and the caller exits. The first
/// process watches for that file and shows its window, so launching the Hub
/// again, from the Start menu or a shortcut, brings the running one forward
/// (also out of the tray) instead of starting a second copy with a second tray
/// icon, update watch and catalog fetches.
///
/// The directory is the cache folder, which every build of the Hub shares.
/// Development builds pass a different [name], so running from source next to
/// the installed Hub does not hand control to the installed one.
class SingleInstance {
  SingleInstance._(this.directory, this.name, this._lock);

  final Directory directory;
  final String name;
  final RandomAccessFile _lock;
  StreamSubscription<FileSystemEvent>? _watch;

  static File _lockFile(Directory directory, String name) =>
      File('${directory.path}${Platform.pathSeparator}$name.lock');

  static File _requestFile(Directory directory, String name) =>
      File('${directory.path}${Platform.pathSeparator}$name.show');

  /// The lock, or null when another process already runs. In that case that
  /// process has been asked to show its window and the caller should exit.
  static Future<SingleInstance?> acquire(
    Directory directory, {
    String name = 'instance',
  }) async {
    await directory.create(recursive: true);
    final lock = await _lockFile(directory, name).open(mode: FileMode.write);
    try {
      await lock.lock(FileLock.exclusive);
    } on FileSystemException {
      await lock.close();
      await requestShow(directory, name: name);
      return null;
    }
    // A request left behind by a process that died is not about this one.
    try {
      await _requestFile(directory, name).delete();
    } on FileSystemException {
      // None there.
    }
    return SingleInstance._(directory, name, lock);
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

  /// Stops listening and gives the lock up. Ending the process does the same.
  Future<void> release() async {
    await _watch?.cancel();
    _watch = null;
    await _lock.close();
  }
}
