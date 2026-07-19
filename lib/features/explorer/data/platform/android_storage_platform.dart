import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:flutter/services.dart';

class AndroidStoragePlatform {
  const AndroidStoragePlatform({
    MethodChannel channel = const MethodChannel(
      'com.ajayff4.fileexplorer/storage',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<List<StorageVolume>> getStorageVolumes() async {
    final result =
        await _channel.invokeListMethod<Object?>('getStorageVolumes');
    final rawVolumes = result ?? const <Object?>[];

    return rawVolumes
        .whereType<Map<Object?, Object?>>()
        .map(_volumeFromMap)
        .toList(growable: false);
  }

  Future<StorageSummary> getStorageStats({
    required String label,
    required String path,
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getStorageStats',
      {'path': path},
    );
    final stats = result ?? const <Object?, Object?>{};
    final totalBytes = _intFrom(stats['totalBytes']);
    final freeBytes = _intFrom(stats['freeBytes']);

    return StorageSummary(
      label: label,
      usedBytes: (totalBytes - freeBytes).clamp(0, totalBytes),
      totalBytes: totalBytes <= 0 ? 1 : totalBytes,
    );
  }

  Future<bool> isAllFilesAccessGranted() async {
    return await _channel.invokeMethod<bool>('isAllFilesAccessGranted') ??
        false;
  }

  StorageVolume _volumeFromMap(Map<Object?, Object?> map) {
    final label = map['label']?.toString() ?? 'Storage';
    final path = map['path']?.toString() ?? '/storage/emulated/0';
    final totalBytes = _intFrom(map['totalBytes']);
    final freeBytes = _intFrom(map['freeBytes']);
    final usedBytes = _intFrom(map['usedBytes']);

    return StorageVolume(
      id: map['id']?.toString() ?? path,
      label: label,
      path: path,
      isPrimary: map['isPrimary'] == true,
      summary: StorageSummary(
        label: label,
        usedBytes: usedBytes <= 0 ? (totalBytes - freeBytes) : usedBytes,
        totalBytes: totalBytes <= 0 ? 1 : totalBytes,
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
