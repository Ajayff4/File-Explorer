import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

const _thumbnailChannel = MethodChannel('com.ajayff4.fileexplorer/thumbnail');

final _memory = <String, Uint8List?>{};
final _inflight = <String, Future<Uint8List?>>{};
Directory? _cacheDir;

Future<Directory> _ensureCacheDir() async {
  if (_cacheDir != null) {
    return _cacheDir!;
  }
  final base = await getApplicationCacheDirectory();
  final dir = Directory('${base.path}/thumbnails');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  _cacheDir = dir;
  return dir;
}

String _key(String path, int maxWidth) =>
    '${maxWidth}_${path.hashCode}_${path.length}';

Future<Uint8List?> _readDisk(String key) async {
  try {
    final dir = await _ensureCacheDir();
    final file = File('${dir.path}/$key.jpg');
    if (await file.exists()) {
      return file.readAsBytes();
    }
  } catch (_) {}
  return null;
}

Future<void> _writeDisk(String key, Uint8List bytes) async {
  try {
    final dir = await _ensureCacheDir();
    await File('${dir.path}/$key.jpg').writeAsBytes(bytes, flush: true);
    await _evictIfNeeded(dir);
  } catch (_) {}
}

/// Keeps the disk cache bounded. Sorted by last-modified, oldest deleted first.
Future<void> _evictIfNeeded(Directory dir) async {
  try {
    final files = (await dir.list().toList()).whereType<File>().toList();
    if (files.length <= 300) {
      return;
    }
    files.sort((a, b) {
      final am = a.lastModifiedSync();
      final bm = b.lastModifiedSync();
      return am.compareTo(bm);
    });
    while (files.length > 300) {
      final oldest = files.removeAt(0);
      try {
        await oldest.delete();
      } catch (_) {}
    }
  } catch (_) {}
}

/// Native MediaStore thumbnail for [path], backed by an in-memory and disk
/// cache. Returns null when the OS has no thumbnail (caller falls back).
Future<Uint8List?> nativeThumbnail(String path, int maxWidth) {
  final key = _key(path, maxWidth);
  final cached = _memory[key];
  if (cached != null) {
    return Future.value(cached);
  }
  final inflight = _inflight[key];
  if (inflight != null) {
    return inflight;
  }

  final future = _loadNative(key, path, maxWidth);
  _inflight[key] = future;
  future.whenComplete(() => _inflight.remove(key));
  return future;
}

Future<Uint8List?> _loadNative(String key, String path, int maxWidth) async {
  final disk = await _readDisk(key);
  if (disk != null) {
    _memory[key] = disk;
    return disk;
  }
  try {
    final bytes = await _thumbnailChannel.invokeMethod<Uint8List>(
      'getThumbnail',
      {'path': path, 'maxWidth': maxWidth},
    );
    if (bytes != null && bytes.isNotEmpty) {
      _memory[key] = bytes;
      await _writeDisk(key, bytes);
      return bytes;
    }
  } on PlatformException {
    // Fall through to the caller's fallback.
  } on MissingPluginException {
    // Non-Android: no native thumbnail channel.
  }
  return null;
}

/// Decoded video thumbnail via the bundled `video_thumbnail` plugin, using the
/// same disk cache. Used when the OS has no indexed thumbnail for a video.
Future<Uint8List?> decodedVideoThumbnail(String path, int maxWidth) {
  final key = _key(path, maxWidth);
  final cached = _memory[key];
  if (cached != null) {
    return Future.value(cached);
  }
  final inflight = _inflight[key];
  if (inflight != null) {
    return inflight;
  }

  final future = _loadDecoded(key, path, maxWidth);
  _inflight[key] = future;
  future.whenComplete(() => _inflight.remove(key));
  return future;
}

Future<Uint8List?> _loadDecoded(String key, String path, int maxWidth) async {
  final disk = await _readDisk(key);
  if (disk != null) {
    _memory[key] = disk;
    return disk;
  }
  try {
    final cacheDir = await _ensureCacheDir();
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: path,
      thumbnailPath: cacheDir.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: maxWidth,
      quality: 70,
    );
    if (thumbPath != null) {
      final file = File(thumbPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _memory[key] = bytes;
        await _writeDisk(key, bytes);
        try {
          await file.delete();
        } catch (_) {}
        return bytes;
      }
    }
  } catch (_) {}
  return null;
}
