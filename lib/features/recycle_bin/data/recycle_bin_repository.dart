import 'dart:convert';
import 'dart:io';

import 'package:file_explorer/features/recycle_bin/domain/entities/trash_item.dart';
import 'package:path/path.dart' as p;

/// Moves deleted files into a hidden `.recycle_bin` directory at the volume
/// root instead of erasing them, so they can be restored or emptied later.
class RecycleBinRepository {
  const RecycleBinRepository();

  /// Name of the trash directory, relative to the volume root.
  static const trashDirName = '.recycle_bin';

  static String trashRootFor(String volumeRoot) =>
      p.join(volumeRoot, trashDirName);

  /// Moves [sourcePath] to the trash directory derived from its own volume.
  Future<TrashItem> moveToTrash(String sourcePath) {
    return moveToTrashTo(sourcePath, trashRootFor(_volumeRootFor(sourcePath)));
  }

  Future<TrashItem> moveToTrashTo(String sourcePath, String trashRoot) async {
    final type = await FileSystemEntity.type(sourcePath, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      throw FileSystemException('Source not found', sourcePath);
    }

    await Directory(trashRoot).create(recursive: true);

    final name = p.basename(sourcePath);
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}_$name';
    final trashPath = p.join(trashRoot, id);
    final isFolder = type == FileSystemEntityType.directory;

    int? sizeBytes;
    if (!isFolder) {
      try {
        sizeBytes = await File(sourcePath).length();
      } catch (_) {
        sizeBytes = null;
      }
    }

    if (isFolder) {
      await Directory(sourcePath).rename(trashPath);
    } else {
      await File(sourcePath).rename(trashPath);
    }

    final item = TrashItem(
      id: id,
      originalPath: sourcePath,
      trashPath: trashPath,
      name: name,
      deletedAt: now,
      isFolder: isFolder,
      sizeBytes: sizeBytes,
    );
    await _writeMeta(item);
    return item;
  }

  Future<List<TrashItem>> listTrash(String trashRoot) async {
    final dir = Directory(trashRoot);
    if (!await dir.exists()) {
      return const [];
    }

    final items = <TrashItem>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity.path.endsWith('.meta.json')) continue;
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.file ||
          type == FileSystemEntityType.directory) {
        items.add(await _readMeta(
          entity.path,
          id: p.basename(entity.path),
          isFolder: type == FileSystemEntityType.directory,
        ));
      }
    }
    items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return items;
  }

  Future<void> restore(TrashItem item) async {
    if (item.originalPath.isEmpty) {
      throw const FileSystemException('Original path unknown');
    }
    final original = item.originalPath;
    await Directory(p.dirname(original)).create(recursive: true);

    var target = original;
    if (await _exists(target)) {
      target = _uniquePath(target);
    }

    if (item.isFolder) {
      await Directory(item.trashPath).rename(target);
    } else {
      await File(item.trashPath).rename(target);
    }
    await _deleteMeta(item);
  }

  Future<void> deletePermanently(TrashItem item) async {
    final type = await FileSystemEntity.type(item.trashPath, followLinks: false);
    if (type == FileSystemEntityType.file) {
      await File(item.trashPath).delete();
    } else if (type == FileSystemEntityType.directory) {
      await Directory(item.trashPath).delete(recursive: true);
    }
    await _deleteMeta(item);
  }

  Future<void> emptyTrash(String trashRoot) async {
    final dir = Directory(trashRoot);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  String _metaPath(TrashItem item) => '${item.trashPath}.meta.json';

  Future<void> _writeMeta(TrashItem item) async {
    await File(_metaPath(item)).writeAsString(
      jsonEncode({
        'originalPath': item.originalPath,
        'name': item.name,
        'deletedAtMs': item.deletedAt.millisecondsSinceEpoch,
        'isFolder': item.isFolder,
        'sizeBytes': item.sizeBytes,
      }),
    );
  }

  Future<void> _deleteMeta(TrashItem item) async {
    try {
      final file = File(_metaPath(item));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<TrashItem> _readMeta(
    String trashPath, {
    required String id,
    required bool isFolder,
  }) async {
    var json = const <String, dynamic>{};
    try {
      final file = File('$trashPath.meta.json');
      if (await file.exists()) {
        json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {}

    return TrashItem(
      id: id,
      originalPath: json['originalPath']?.toString() ?? '',
      trashPath: trashPath,
      name: json['name']?.toString() ?? p.basename(trashPath),
      deletedAt: DateTime.fromMillisecondsSinceEpoch(
        json['deletedAtMs'] as int? ?? 0,
      ),
      isFolder: isFolder,
      sizeBytes: json['sizeBytes'] as int?,
    );
  }

  Future<bool> _exists(String path) async {
    return await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.notFound;
  }

  String _uniquePath(String path) {
    final directory = p.dirname(path);
    final extension = p.extension(path);
    final baseName = p.basenameWithoutExtension(path);
    var sequence = 1;
    while (true) {
      final candidate = p.join(directory, '$baseName ($sequence)$extension');
      if (!File(candidate).existsSync() && !Directory(candidate).existsSync()) {
        return candidate;
      }
      sequence += 1;
    }
  }
}

/// Derives the volume root of [path]. On Android shared storage the root is
/// `/storage/<volume>/<user>`; anything else falls back to the filesystem root.
String _volumeRootFor(String path) {
  final normalized = p.normalize(path);
  final parts = normalized.split('/').where((s) => s.isNotEmpty).toList();
  if (parts.length >= 3 && parts.first == 'storage') {
    return '/${parts.sublist(0, 3).join('/')}';
  }
  return p.rootPrefix(normalized);
}
