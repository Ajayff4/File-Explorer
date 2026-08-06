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

  int _intFrom(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value) ?? 0,
      _ => 0,
    };
  }
}
