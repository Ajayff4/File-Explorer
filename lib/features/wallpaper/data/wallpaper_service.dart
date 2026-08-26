import 'dart:async';

import 'package:flutter/services.dart';

const _wallpaperChannel = MethodChannel('com.ajayff4.fileexplorer/wallpaper');

/// Result of saving the device's current wallpapers to local storage.
class SavedWallpaper {
  const SavedWallpaper({
    this.homePath,
    this.lockPath,
    required this.directory,
  });

  /// Absolute path of the saved home-screen wallpaper, or `null` if unavailable.
  final String? homePath;

  /// Absolute path of the saved lock-screen wallpaper, or `null` if unavailable.
  final String? lockPath;

  /// Directory the wallpapers were written into (`.../File Explorer/Wallpaper`).
  final String directory;
}

/// Saves the current home and lock screen wallpapers into
/// `File Explorer/Wallpaper` and returns their saved locations.
///
/// Throws a [PlatformException] if the native call fails.
Future<SavedWallpaper> saveCurrentWallpapers() async {
  final result =
      await _wallpaperChannel.invokeMethod<Map<dynamic, dynamic>>('saveWallpaper');
  if (result == null) {
    throw PlatformException(
      code: 'save_wallpaper_failed',
      message: 'No wallpaper data returned',
    );
  }
  return SavedWallpaper(
    homePath: result['home'] as String?,
    lockPath: result['lock'] as String?,
    directory: (result['directory'] as String?) ?? '',
  );
}
