import 'dart:io';

import 'package:hub_core/hub_core.dart';

/// Folder name under the OS per-user cache directory (see [cacheDirectory]).
const hubCacheName = 'Dynamotivation Software Hub';

final Directory hubCacheDirectory = cacheDirectory(hubCacheName);

/// Downloaded catalog icons.
final Directory hubIconCacheDirectory = Directory(
  '${hubCacheDirectory.path}${Platform.pathSeparator}icons',
);
