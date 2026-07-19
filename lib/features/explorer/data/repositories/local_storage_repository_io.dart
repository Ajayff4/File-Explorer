import 'dart:io';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:path/path.dart' as p;

class LocalStorageRepository implements StorageRepository {
  const LocalStorageRepository();

  @override
  Future<List<StorageVolume>> getStorageVolumes() async {
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

    return DirectoryListing(
      path: path,
      volume: StorageVolume(
        id: 'local-primary',
        label: _defaultRootLabel(),
        path: _defaultRootPath(),
        isPrimary: true,
      ),
      entries: entries,
    );
  }

  Future<FileSystemEntry> _mapEntity(FileSystemEntity entity) async {
    final stat = await entity.stat();
    final type = stat.type == FileSystemEntityType.directory
        ? FileSystemEntryType.folder
        : _typeFromPath(entity.path);

    return FileSystemEntry(
      name: p.basename(entity.path),
      path: entity.path,
      type: type,
      modifiedAt: stat.modified,
      sizeBytes: stat.type == FileSystemEntityType.file ? stat.size : null,
      childrenCount: null,
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
