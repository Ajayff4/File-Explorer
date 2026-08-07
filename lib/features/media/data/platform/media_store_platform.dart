import 'package:flutter/services.dart';

enum MediaStoreMediaType { image, audio, video }

class MediaStoreMediaItem {
  const MediaStoreMediaItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
}

class MediaStorePlatform {
  const MediaStorePlatform({
    MethodChannel channel = const MethodChannel(
      'com.ajayff4.fileexplorer/media_store',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<List<MediaStoreMediaItem>> queryMedia(MediaStoreMediaType type) async {
    final result = await _channel.invokeListMethod<Object?>(
      'queryMedia',
      {'type': type.name},
    );
    final rawItems = result ?? const <Object?>[];

    return rawItems
        .whereType<Map<Object?, Object?>>()
        .map(_itemFromMap)
        .where((item) => item.path.isNotEmpty)
        .toList(growable: false);
  }

  /// Queries every indexed file under [rootPath] from MediaStore's Files
  /// collection.
  ///
  /// Unlike [queryMedia], this covers non-media kinds too (documents,
  /// archives, apps), letting the folder view answer from MediaStore instead
  /// of a filesystem listing. Same hidden-segment filtering as [queryMedia].
  Future<List<MediaStoreMediaItem>> queryFiles({
    required String rootPath,
  }) async {
    final result = await _channel.invokeListMethod<Object?>(
      'queryFiles',
      {'path': rootPath},
    );
    final rawItems = result ?? const <Object?>[];

    return rawItems
        .whereType<Map<Object?, Object?>>()
        .map(_itemFromMap)
        .where((item) => item.path.isNotEmpty)
        .toList(growable: false);
  }

  MediaStoreMediaItem _itemFromMap(Map<Object?, Object?> map) {
    return MediaStoreMediaItem(
      path: map['path']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sizeBytes: _intFrom(map['sizeBytes']),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        _intFrom(map['modifiedAtMs']),
      ),
    );
  }

  /// Counts media items of [type] inside [rootPath] and its subfolders.
  ///
  /// Matches [queryMedia]'s hidden-segment filtering so counts agree with the
  /// category views. Throws on failure so callers can fall back to the walker.
  Future<int> countMedia(
    MediaStoreMediaType type, {
    required String rootPath,
  }) async {
    final result = await _channel.invokeMethod<int>('countMedia', {
      'type': type.name,
      'path': rootPath,
    });
    return result ?? 0;
  }

  /// Asks the OS media scanner to index (or prune) the given [paths].
  ///
  /// Scan newly created files so they appear in MediaStore-backed views
  /// immediately; scanning paths that no longer exist prunes stale rows.
  Future<void> scanFiles(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }
    await _channel.invokeMethod<void>('scanFiles', {'paths': paths});
  }

  int _intFrom(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value) ?? 0,
      _ => 0,
    };
  }
}
