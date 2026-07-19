import 'dart:io';

import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:path/path.dart' as p;

class LocalTransferExecutor implements TransferExecutor {
  const LocalTransferExecutor();

  @override
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  }) async {
    final sources = task.sourcePaths;
    if (sources.isEmpty) {
      throw const FileSystemException('No source paths provided');
    }

    var transferredBytes = 0;
    final totalBytes = task.progress.totalBytes ?? await _totalBytes(sources);

    void report(String path) {
      onProgress(
        TransferProgress(
          transferredBytes: transferredBytes,
          totalBytes: totalBytes == 0 ? 1 : totalBytes,
          currentItemPath: path,
        ),
      );
    }

    for (final sourcePath in sources) {
      switch (task.operation) {
        case TransferOperation.copy:
          final destinationRoot = _requireDestination(task);
          await _copyPath(
            sourcePath,
            _destinationChildPath(sourcePath, destinationRoot),
            onBytes: (bytes) {
              transferredBytes += bytes;
              report(sourcePath);
            },
          );
        case TransferOperation.move:
          final destinationRoot = _requireDestination(task);
          await _movePath(
            sourcePath,
            _destinationChildPath(sourcePath, destinationRoot),
            onBytes: (bytes) {
              transferredBytes += bytes;
              report(sourcePath);
            },
          );
        case TransferOperation.delete:
          final bytes = await _pathSize(sourcePath);
          await _deletePath(sourcePath);
          transferredBytes += bytes == 0 ? 1 : bytes;
          report(sourcePath);
        case TransferOperation.rename:
          final destinationPath = _requireDestination(task);
          await _renamePath(sourcePath, destinationPath);
          transferredBytes = totalBytes == 0 ? 1 : totalBytes;
          report(sourcePath);
      }
    }
  }

  String _requireDestination(TransferTask task) {
    final destination = task.destinationPath;
    if (destination == null || destination.isEmpty) {
      throw const FileSystemException('Destination path required');
    }
    return destination;
  }

  String _destinationChildPath(String sourcePath, String destinationRoot) {
    return p.join(destinationRoot, p.basename(sourcePath));
  }

  Future<int> _totalBytes(List<String> paths) async {
    var total = 0;
    for (final path in paths) {
      total += await _pathSize(path);
    }
    return total;
  }

  Future<int> _pathSize(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.file) {
      return File(path).length();
    }
    if (type == FileSystemEntityType.directory) {
      var total = 0;
      await for (final entity
          in Directory(path).list(recursive: true, followLinks: false)) {
        if (await FileSystemEntity.isFile(entity.path)) {
          total += await File(entity.path).length();
        }
      }
      return total;
    }
    throw FileSystemException('Source path not found', path);
  }

  Future<void> _copyPath(
    String sourcePath,
    String destinationPath, {
    required void Function(int bytes) onBytes,
  }) async {
    final type = await FileSystemEntity.type(sourcePath, followLinks: false);
    if (type == FileSystemEntityType.file) {
      await _copyFile(sourcePath, destinationPath, onBytes: onBytes);
      return;
    }
    if (type == FileSystemEntityType.directory) {
      await _copyDirectory(sourcePath, destinationPath, onBytes: onBytes);
      return;
    }
    throw FileSystemException('Source path not found', sourcePath);
  }

  Future<void> _copyFile(
    String sourcePath,
    String destinationPath, {
    required void Function(int bytes) onBytes,
  }) async {
    if (await FileSystemEntity.type(destinationPath, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw FileSystemException('Destination already exists', destinationPath);
    }

    await Directory(p.dirname(destinationPath)).create(recursive: true);
    final input = File(sourcePath).openRead();
    final output = File(destinationPath).openWrite();
    try {
      await for (final chunk in input) {
        output.add(chunk);
        onBytes(chunk.length);
      }
    } finally {
      await output.close();
    }
  }

  Future<void> _copyDirectory(
    String sourcePath,
    String destinationPath, {
    required void Function(int bytes) onBytes,
  }) async {
    if (await FileSystemEntity.type(destinationPath, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw FileSystemException('Destination already exists', destinationPath);
    }

    await Directory(destinationPath).create(recursive: true);
    await for (final entity
        in Directory(sourcePath).list(recursive: true, followLinks: false)) {
      final relativePath = p.relative(entity.path, from: sourcePath);
      final targetPath = p.join(destinationPath, relativePath);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await _copyFile(entity.path, targetPath, onBytes: onBytes);
      }
    }
  }

  Future<void> _movePath(
    String sourcePath,
    String destinationPath, {
    required void Function(int bytes) onBytes,
  }) async {
    try {
      await _renamePath(sourcePath, destinationPath);
      onBytes(await _pathSize(destinationPath));
    } on FileSystemException {
      await _copyPath(sourcePath, destinationPath, onBytes: onBytes);
      await _deletePath(sourcePath);
    }
  }

  Future<void> _renamePath(String sourcePath, String destinationPath) async {
    if (await FileSystemEntity.type(destinationPath, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw FileSystemException('Destination already exists', destinationPath);
    }

    await Directory(p.dirname(destinationPath)).create(recursive: true);
    final type = await FileSystemEntity.type(sourcePath, followLinks: false);
    if (type == FileSystemEntityType.file) {
      await File(sourcePath).rename(destinationPath);
      return;
    }
    if (type == FileSystemEntityType.directory) {
      await Directory(sourcePath).rename(destinationPath);
      return;
    }
    throw FileSystemException('Source path not found', sourcePath);
  }

  Future<void> _deletePath(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.file) {
      await File(path).delete();
      return;
    }
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
      return;
    }
    throw FileSystemException('Source path not found', path);
  }
}

TransferExecutor createTransferExecutor() {
  return const LocalTransferExecutor();
}
