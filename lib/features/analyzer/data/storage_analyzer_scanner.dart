import 'dart:io';
import 'dart:isolate';

import 'package:file_explorer/features/analyzer/domain/entities/storage_analysis.dart';

const _imageExts = {
  'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'heic', 'heif',
};
const _videoExts = {
  'mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm', 'm4v', '3gp',
};
const _audioExts = {
  'mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a', 'opus', 'aiff',
};
const _docExts = {
  'pdf', 'doc', 'docx', 'odt', 'rtf', 'txt', 'md', 'log',
  'xls', 'xlsx', 'ods', 'csv', 'ppt', 'pptx', 'odp',
};
const _archiveExts = {
  'zip', 'tar', 'gz', 'bz2', 'xz', 'tgz', 'tbz2', 'txz', '7z', 'rar',
};
const _appExts = {'apk', 'apks', 'xapk', 'apkm', 'aab'};

String _categoryForPath(String path) {
  final dot = path.lastIndexOf('.');
  final ext = (dot > 0 && dot < path.length - 1)
      ? path.substring(dot + 1).toLowerCase()
      : '';
  if (_imageExts.contains(ext)) return 'image';
  if (_videoExts.contains(ext)) return 'video';
  if (_audioExts.contains(ext)) return 'audio';
  if (_docExts.contains(ext)) return 'document';
  if (_archiveExts.contains(ext)) return 'archive';
  if (_appExts.contains(ext)) return 'app';
  return 'other';
}

/// Recursively accumulates sizes, skipping directories that cannot be listed
/// (e.g. `/Android/data` on Android 11+ even with all-files access). Returns
/// the total size of [dir]'s subtree.
int _walkSync(
  Directory dir,
  Map<String, int> categoryBytes,
  Map<String, int> folderBytes,
  List<LargeFile> files,
) {
  List<FileSystemEntity> entities;
  try {
    entities = dir.listSync(followLinks: false);
  } catch (_) {
    return 0;
  }

  var total = 0;
  for (final entity in entities) {
    if (entity is File) {
      var size = 0;
      try {
        size = entity.lengthSync();
      } catch (_) {
        size = 0;
      }
      if (size <= 0) continue;

      total += size;
      final path = entity.path;
      final category = _categoryForPath(path);
      categoryBytes[category] = (categoryBytes[category] ?? 0) + size;
      files.add(LargeFile(path: path, bytes: size, category: category));
    } else if (entity is Directory) {
      total += _walkSync(entity, categoryBytes, folderBytes, files);
    }
  }

  folderBytes[dir.path] = total;
  return total;
}

StorageAnalysis _scanSync(String rootPath) {
  final categoryBytes = <String, int>{};
  final folderBytes = <String, int>{};
  final files = <LargeFile>[];

  var totalBytes = 0;
  try {
    totalBytes =
        _walkSync(Directory(rootPath), categoryBytes, folderBytes, files);
  } catch (_) {
    totalBytes = 0;
  }

  files.sort((a, b) => b.bytes.compareTo(a.bytes));

  final folders = folderBytes.entries
      .where((entry) => entry.key != rootPath)
      .map((entry) => FolderUsage(path: entry.key, bytes: entry.value))
      .toList()
    ..sort((a, b) => b.bytes.compareTo(a.bytes));

  return StorageAnalysis(
    rootPath: rootPath,
    totalBytes: totalBytes,
    fileCount: files.length,
    folderCount: folderBytes.length,
    categories: [
      for (final entry in categoryBytes.entries)
        CategoryUsage(category: entry.key, bytes: entry.value),
    ]..sort((a, b) => b.bytes.compareTo(a.bytes)),
    folders: folders,
    files: files.take(100).toList(),
  );
}

/// Scans [rootPath] recursively on a background isolate so the UI thread never
/// blocks. Returns an aggregated [StorageAnalysis].
Future<StorageAnalysis> scanStorage(String rootPath) {
  return Isolate.run(() => _scanSync(rootPath));
}
