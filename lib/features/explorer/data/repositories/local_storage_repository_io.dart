import 'dart:io';

import 'package:file_explorer/features/explorer/data/platform/android_storage_platform.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:path/path.dart' as p;

class LocalStorageRepository implements StorageRepository {
  const LocalStorageRepository({
    this.androidStoragePlatform = const AndroidStoragePlatform(),
  });

  final AndroidStoragePlatform androidStoragePlatform;

  @override
  Future<List<StorageVolume>> getStorageVolumes() async {
    if (Platform.isAndroid) {
      final volumes = await androidStoragePlatform.getStorageVolumes();
      if (volumes.isNotEmpty) {
        return volumes;
      }
    }

    final primaryPath = _defaultRootPath();
    return [
      StorageVolume(
        id: 'local-primary',
        label: _defaultRootLabel(),
        path: primaryPath,
        summary: await getPrimaryStorageSummary(),
        isPrimary: true,
      ),
    ];
  }

  @override
  Future<StorageSummary> getPrimaryStorageSummary() async {
    if (Platform.isAndroid) {
      final volumes = await getStorageVolumes();
      final primaryVolume = _primaryVolumeFrom(volumes);
      if (primaryVolume?.summary != null) {
        return primaryVolume!.summary!;
      }
      if (primaryVolume != null) {
        return androidStoragePlatform.getStorageStats(
          label: primaryVolume.label,
          path: primaryVolume.path,
        );
      }
    }

    final rootPath = _defaultRootPath();
    final stat = await _tryFileSystemEntityStat(rootPath);

    return StorageSummary(
      label: _defaultRootLabel(),
      usedBytes: 0,
      totalBytes: stat?.size == null || stat!.size <= 0 ? 1 : stat.size,
    );
  }

  @override
  Future<DirectoryListing> listDirectory(String path) async {
    final directory = Directory(path);
    final entities = await directory.list().toList();
    final entries = await Future.wait(entities.map(_mapEntity));
    entries.sort(_compareEntries);
    final volumes = await getStorageVolumes();
    final volume = _volumeForPath(path, volumes) ?? _primaryVolumeFrom(volumes);

    return DirectoryListing(
      path: path,
      volume: volume,
      entries: entries,
    );
  }

  Future<FileSystemEntry> _mapEntity(FileSystemEntity entity) async {
    final stat = await entity.stat();
    final type = stat.type == FileSystemEntityType.directory
        ? FileSystemEntryType.folder
        : _typeFromPath(entity.path);

    int? childrenCount;
    if (stat.type == FileSystemEntityType.directory) {
      try {
        final dir = Directory(entity.path);
        final children = await dir.list().length;
        childrenCount = children;
      } on FileSystemException {
        childrenCount = null;
      }
    }

    return FileSystemEntry(
      name: p.basename(entity.path),
      path: entity.path,
      type: type,
      modifiedAt: stat.modified,
      sizeBytes: stat.type == FileSystemEntityType.file ? stat.size : null,
      childrenCount: childrenCount,
    );
  }

  int _compareEntries(FileSystemEntry left, FileSystemEntry right) {
    if (left.isFolder != right.isFolder) {
      return left.isFolder ? -1 : 1;
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  }

  Future<FileStat?> _tryFileSystemEntityStat(String path) async {
    try {
      return await FileStat.stat(path);
    } on FileSystemException {
      return null;
    }
  }

  StorageVolume? _primaryVolumeFrom(List<StorageVolume> volumes) {
    for (final volume in volumes) {
      if (volume.isPrimary) {
        return volume;
      }
    }
    return volumes.isEmpty ? null : volumes.first;
  }

  StorageVolume? _volumeForPath(String path, List<StorageVolume> volumes) {
    StorageVolume? bestMatch;
    for (final volume in volumes) {
      if (path.startsWith(volume.path) &&
          (bestMatch == null || volume.path.length > bestMatch.path.length)) {
        bestMatch = volume;
      }
    }
    return bestMatch;
  }

  FileSystemEntryType _typeFromPath(String path) {
    final extension = p.extension(path).toLowerCase();
    return switch (extension) {
      '.jpg' ||
      '.jpeg' ||
      '.png' ||
      '.gif' ||
      '.webp' ||
      '.heic' =>
        FileSystemEntryType.image,
      '.mp4' ||
      '.mkv' ||
      '.mov' ||
      '.webm' ||
      '.avi' =>
        FileSystemEntryType.video,
      '.mp3' ||
      '.flac' ||
      '.wav' ||
      '.m4a' ||
      '.ogg' =>
        FileSystemEntryType.audio,
      '.pdf' ||
      '.doc' ||
      '.docx' ||
      '.txt' ||
      '.md' ||
      '.xls' ||
      '.xlsx' =>
        FileSystemEntryType.document,
      '.zip' ||
      '.rar' ||
      '.7z' ||
      '.tar' ||
      '.gz' =>
        FileSystemEntryType.archive,
      '.apk' || '.app' || '.exe' || '.deb' => FileSystemEntryType.app,
      _ => FileSystemEntryType.other,
    };
  }

  String _defaultRootPath() {
    if (Platform.isAndroid) {
      return '/storage/emulated/0';
    }
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return home == null || home.isEmpty ? Directory.current.path : home;
  }

  String _defaultRootLabel() {
    if (Platform.isAndroid) {
      return 'Internal storage';
    }
    return 'Home';
  }
}

StorageRepository createStorageRepository() {
  return const LocalStorageRepository();
}
