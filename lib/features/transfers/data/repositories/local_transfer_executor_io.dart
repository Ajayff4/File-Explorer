import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:file_explorer/shared/archive/archive_format.dart';
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

    if (task.operation == TransferOperation.compressArchive) {
      final destinationPath = _compressDestinationPath(task, sources);
      await _compressPaths(sources, destinationPath, task: task);
      transferredBytes = totalBytes == 0 ? 1 : totalBytes;
      report(destinationPath);
      return;
    }

    for (final sourcePath in sources) {
      switch (task.operation) {
        case TransferOperation.copy:
          final destinationRoot = _requireDestination(task);
          await _copyPath(
            sourcePath,
            _destinationChildPath(sourcePath, destinationRoot),
            task: task,
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
            task: task,
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
          await _renamePath(sourcePath, destinationPath, task: task);
          transferredBytes = totalBytes == 0 ? 1 : totalBytes;
          report(sourcePath);
        case TransferOperation.extractArchive:
          await _extractArchive(sourcePath, task: task);
          transferredBytes += await _progressBytes(sourcePath);
          report(sourcePath);
        case TransferOperation.compressArchive:
          throw StateError('Compression is handled before source iteration');
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
    required TransferTask task,
    required void Function(int bytes) onBytes,
  }) async {
    final targetPath = await _resolveDestinationPath(
      destinationPath,
      task: task,
    );
    if (targetPath == null) {
      onBytes(await _progressBytes(sourcePath));
      return;
    }

    await _copyPathIntoAvailableTarget(
      sourcePath,
      targetPath,
      onBytes: onBytes,
    );
  }

  Future<void> _copyPathIntoAvailableTarget(
    String sourcePath,
    String destinationPath, {
    required void Function(int bytes) onBytes,
  }) async {
    final type = await FileSystemEntity.type(sourcePath, followLinks: false);
    if (type == FileSystemEntityType.file) {
      await _copyFileIntoAvailableTarget(
        sourcePath,
        destinationPath,
        onBytes: onBytes,
      );
      return;
    }
    if (type == FileSystemEntityType.directory) {
      await _copyDirectoryIntoAvailableTarget(
        sourcePath,
        destinationPath,
        onBytes: onBytes,
      );
      return;
    }
    throw FileSystemException('Source path not found', sourcePath);
  }

  Future<void> _copyFileIntoAvailableTarget(
    String sourcePath,
    String destinationPath, {
    required void Function(int bytes) onBytes,
  }) async {
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

  Future<void> _copyDirectoryIntoAvailableTarget(
    String sourcePath,
    String destinationPath, {
    required void Function(int bytes) onBytes,
  }) async {
    await Directory(destinationPath).create(recursive: true);
    await for (final entity
        in Directory(sourcePath).list(recursive: true, followLinks: false)) {
      final relativePath = p.relative(entity.path, from: sourcePath);
      final targetPath = p.join(destinationPath, relativePath);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await _copyFileIntoAvailableTarget(
          entity.path,
          targetPath,
          onBytes: onBytes,
        );
      }
    }
  }

  Future<void> _movePath(
    String sourcePath,
    String destinationPath, {
    required TransferTask task,
    required void Function(int bytes) onBytes,
  }) async {
    final targetPath = await _resolveDestinationPath(
      destinationPath,
      task: task,
    );
    if (targetPath == null) {
      onBytes(await _progressBytes(sourcePath));
      return;
    }

    final movedBytes = await _progressBytes(sourcePath);
    try {
      await _renamePathIntoAvailableTarget(sourcePath, targetPath);
      onBytes(movedBytes);
    } on FileSystemException {
      await _copyPathIntoAvailableTarget(sourcePath, targetPath,
          onBytes: onBytes);
      await _deletePath(sourcePath);
    }
  }

  Future<void> _renamePath(
    String sourcePath,
    String destinationPath, {
    required TransferTask task,
  }) async {
    final targetPath = await _resolveDestinationPath(
      destinationPath,
      task: task,
    );
    if (targetPath == null) {
      return;
    }

    await _renamePathIntoAvailableTarget(sourcePath, targetPath);
  }

  Future<void> _renamePathIntoAvailableTarget(
    String sourcePath,
    String destinationPath,
  ) async {
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

  Future<void> _extractArchive(
    String sourcePath, {
    required TransferTask task,
  }) async {
    final format = _archiveFormatForPath(sourcePath);
    if (format == null) {
      throw FileSystemException('Unsupported archive format', sourcePath);
    }

    final destinationRoot = task.destinationPath ?? p.dirname(sourcePath);
    switch (format) {
      case ArchiveFormat.zip:
        await Directory(destinationRoot).create(recursive: true);
        final inputStream = InputFileStream(sourcePath);
        try {
          try {
            final archive = ZipDecoder().decodeStream(
              inputStream,
              password: task.archivePassword,
            );
            await _extractArchiveToDirectory(
              archive,
              destinationRoot,
              task: task,
            );
          } catch (error) {
            if (error is TransferExecutionException) {
              rethrow;
            }
            throw TransferExecutionException(
              code: TransferFailureCode.unknown,
              message:
                  'Could not extract ZIP. If it is encrypted, enter the ZIP password.',
              path: sourcePath,
            );
          }
        } finally {
          await inputStream.close();
        }
      case ArchiveFormat.tar ||
            ArchiveFormat.tarGzip ||
            ArchiveFormat.tarBzip2 ||
            ArchiveFormat.tarXz:
        await Directory(destinationRoot).create(recursive: true);
        final tempDir = await Directory.systemTemp.createTemp(
          'file_explorer_archive_',
        );
        final tarPath = p.join(tempDir.path, 'archive.tar');
        try {
          await _decompressToTarFile(sourcePath, tarPath, format);
          final inputStream = InputFileStream(tarPath);
          try {
            final archive = TarDecoder().decodeStream(inputStream);
            await _extractArchiveToDirectory(
              archive,
              destinationRoot,
              task: task,
            );
          } finally {
            await inputStream.close();
          }
        } finally {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      case ArchiveFormat.gzip:
        final destinationPath = await _resolveDestinationPath(
          p.join(destinationRoot, _archiveBaseName(sourcePath)),
          task: task,
        );
        if (destinationPath == null) {
          return;
        }

        await _gunzipFile(sourcePath, destinationPath);
    }
  }

  Future<void> _decompressToTarFile(
    String sourcePath,
    String tarPath,
    ArchiveFormat format,
  ) async {
    switch (format) {
      case ArchiveFormat.tar:
        await File(sourcePath).copy(tarPath);
      case ArchiveFormat.tarGzip:
        await _gunzipFile(sourcePath, tarPath);
      case ArchiveFormat.tarBzip2:
        await _decompressWith(
          sourcePath,
          tarPath,
          (input, output) => BZip2Decoder().decodeStream(input, output),
        );
      case ArchiveFormat.tarXz:
        await _decompressWith(
          sourcePath,
          tarPath,
          (input, output) => XZDecoder().decodeStream(input, output),
        );
      case ArchiveFormat.zip || ArchiveFormat.gzip:
        throw FileSystemException('Not a tar archive', sourcePath);
    }
  }

  Future<void> _decompressWith(
    String sourcePath,
    String destinationPath,
    bool Function(InputStream input, OutputStream output) decode,
  ) async {
    await Directory(p.dirname(destinationPath)).create(recursive: true);
    final inputBytes = await File(sourcePath).readAsBytes();
    final output = OutputMemoryStream();
    try {
      decode(InputMemoryStream(inputBytes), output);
      await File(destinationPath).writeAsBytes(output.getBytes());
    } finally {
      output.closeSync();
    }
  }

  Future<void> _extractArchiveToDirectory(
    Archive archive,
    String destinationRoot, {
    required TransferTask task,
  }) async {
    for (final entry in archive) {
      final relativePath = _safeArchivePath(entry.name);
      if (relativePath == null || relativePath.isEmpty) {
        continue;
      }
      final outputPath = p.join(destinationRoot, relativePath);

      if (entry.isFile) {
        final targetPath =
            await _resolveDestinationPath(outputPath, task: task);
        if (targetPath == null) {
          continue;
        }
        await Directory(p.dirname(targetPath)).create(recursive: true);
        final outputStream = OutputFileStream(targetPath);
        try {
          entry.writeContent(outputStream);
        } finally {
          outputStream.closeSync();
        }
      } else {
        await Directory(outputPath).create(recursive: true);
      }
    }
  }

  String? _safeArchivePath(String archivePath) {
    final normalized = p.normalize(archivePath.replaceAll('\\', '/'));
    if (p.isAbsolute(normalized) ||
        normalized == '.' ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      return null;
    }
    return normalized;
  }

  String _compressDestinationPath(TransferTask task, List<String> sourcePaths) {
    final destination = task.destinationPath;
    if (destination != null && destination.isNotEmpty) {
      return destination;
    }
    final firstSourcePath = sourcePaths.first;
    final format = _defaultCompressionFormat(sourcePaths);
    final archiveName = sourcePaths.length == 1
        ? '${p.basename(firstSourcePath)}${_extensionForArchiveFormat(format)}'
        : 'Archive${_extensionForArchiveFormat(format)}';
    return p.join(p.dirname(firstSourcePath), archiveName);
  }

  Future<void> _compressPaths(
    List<String> sourcePaths,
    String destinationPath, {
    required TransferTask task,
  }) async {
    final targetPath = await _resolveDestinationPath(
      destinationPath,
      task: task,
    );
    if (targetPath == null) {
      return;
    }

    final format = _archiveFormatForPath(targetPath) ?? ArchiveFormat.zip;
    if (format == ArchiveFormat.gzip) {
      if (sourcePaths.length != 1 ||
          await FileSystemEntity.type(
                sourcePaths.single,
                followLinks: false,
              ) !=
              FileSystemEntityType.file) {
        throw FileSystemException(
          'GZip compression supports a single file only',
          targetPath,
        );
      }
      await _gzipFile(
        sourcePaths.single,
        targetPath,
        level: _compressionLevelForTask(task),
      );
      return;
    }

    if (format == ArchiveFormat.tarGzip) {
      await _compressTar(
        sourcePaths,
        targetPath,
        codec: _ArchiveCodec.gzip,
        level: _compressionLevelForTask(task),
      );
      return;
    }

    if (format == ArchiveFormat.tarBzip2) {
      await _compressTar(
        sourcePaths,
        targetPath,
        codec: _ArchiveCodec.bzip2,
      );
      return;
    }

    if (format == ArchiveFormat.tarXz) {
      await _compressTar(sourcePaths, targetPath, codec: _ArchiveCodec.xz);
      return;
    }

    if (format == ArchiveFormat.tar) {
      await _compressTar(sourcePaths, targetPath);
      return;
    }

    await Directory(p.dirname(targetPath)).create(recursive: true);
    final encoder = ZipFileEncoder(password: task.archivePassword);
    final compressionLevel = _compressionLevelForTask(task);
    encoder.create(targetPath, level: compressionLevel);
    try {
      for (final sourcePath in sourcePaths) {
        final type =
            await FileSystemEntity.type(sourcePath, followLinks: false);
        if (type == FileSystemEntityType.file) {
          await encoder.addFile(
            File(sourcePath),
            p.basename(sourcePath),
            compressionLevel,
          );
          continue;
        }
        if (type == FileSystemEntityType.directory) {
          await encoder.addDirectory(
            Directory(sourcePath),
            includeDirName: sourcePaths.length > 1,
            level: compressionLevel,
          );
          continue;
        }
        throw FileSystemException('Source path not found', sourcePath);
      }
    } finally {
      await encoder.close();
    }
  }

  Future<void> _compressTar(
    List<String> sourcePaths,
    String destinationPath, {
    _ArchiveCodec? codec,
    int level = 0,
  }) async {
    if (codec == null) {
      await _writeTarArchive(sourcePaths, destinationPath);
      return;
    }
    await Directory(p.dirname(destinationPath)).create(recursive: true);
    final tempDir =
        await Directory.systemTemp.createTemp('file_explorer_archive_');
    final tarPath = p.join(tempDir.path, 'archive.tar');
    try {
      await _writeTarArchive(sourcePaths, tarPath);
      await _encodeStream(
        tarPath,
        destinationPath,
        codec: codec,
        level: level,
      );
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  Future<void> _writeTarArchive(
    List<String> sourcePaths,
    String destinationPath,
  ) async {
    await Directory(p.dirname(destinationPath)).create(recursive: true);
    final encoder = TarFileEncoder();
    encoder.create(destinationPath);
    try {
      for (final sourcePath in sourcePaths) {
        final type =
            await FileSystemEntity.type(sourcePath, followLinks: false);
        if (type == FileSystemEntityType.file) {
          await encoder.addFile(File(sourcePath), p.basename(sourcePath));
          continue;
        }
        if (type == FileSystemEntityType.directory) {
          await encoder.addDirectory(
            Directory(sourcePath),
            includeDirName: sourcePaths.length > 1,
          );
          continue;
        }
        throw FileSystemException('Source path not found', sourcePath);
      }
    } finally {
      await encoder.close();
    }
  }

  Future<void> _encodeStream(
    String sourcePath,
    String destinationPath, {
    required _ArchiveCodec codec,
    required int level,
  }) async {
    final input = InputFileStream(sourcePath);
    final output = OutputFileStream(destinationPath);
    try {
      switch (codec) {
        case _ArchiveCodec.gzip:
          const GZipEncoder().encodeStream(input, output, level: level);
        case _ArchiveCodec.bzip2:
          BZip2Encoder().encodeStream(input, output);
        case _ArchiveCodec.xz:
          XZEncoder().encodeStream(input, output);
      }
    } finally {
      await input.close();
      await output.close();
    }
  }

  Future<void> _gzipFile(
    String sourcePath,
    String destinationPath, {
    required int level,
  }) async {
    await Directory(p.dirname(destinationPath)).create(recursive: true);
    final input = InputFileStream(sourcePath);
    final output = OutputFileStream(destinationPath);
    try {
      const GZipEncoder().encodeStream(input, output, level: level);
    } finally {
      await input.close();
      await output.close();
    }
  }

  Future<void> _gunzipFile(String sourcePath, String destinationPath) async {
    await Directory(p.dirname(destinationPath)).create(recursive: true);
    final input = InputFileStream(sourcePath);
    final output = OutputFileStream(destinationPath);
    try {
      const GZipDecoder().decodeStream(input, output);
    } finally {
      await input.close();
      await output.close();
    }
  }

  Future<String?> _resolveDestinationPath(
    String destinationPath, {
    required TransferTask task,
  }) async {
    if (!await _exists(destinationPath)) {
      return destinationPath;
    }

    return switch (task.conflictPolicy) {
      ConflictPolicy.ask => throw TransferExecutionException(
          code: TransferFailureCode.destinationExists,
          message: 'Destination already exists',
          path: destinationPath,
        ),
      ConflictPolicy.overwrite => await _overwriteDestination(destinationPath),
      ConflictPolicy.skip => null,
      ConflictPolicy.rename => await _uniquePath(destinationPath),
    };
  }

  Future<String> _overwriteDestination(String destinationPath) async {
    await _deletePath(destinationPath);
    return destinationPath;
  }

  Future<String> _uniquePath(String destinationPath) async {
    final directory = p.dirname(destinationPath);
    final extension = p.extension(destinationPath);
    final baseName = p.basenameWithoutExtension(destinationPath);

    var sequence = 1;
    while (true) {
      final candidate = p.join(directory, '$baseName ($sequence)$extension');
      if (!await _exists(candidate)) {
        return candidate;
      }
      sequence += 1;
    }
  }

  Future<bool> _exists(String path) async {
    return await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.notFound;
  }

  Future<int> _progressBytes(String path) async {
    final bytes = await _pathSize(path);
    return bytes == 0 ? 1 : bytes;
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

ArchiveFormat? _archiveFormatForPath(String path) {
  return archiveFormatForPath(path);
}

ArchiveFormat _defaultCompressionFormat(List<String> sourcePaths) {
  return ArchiveFormat.zip;
}

String _extensionForArchiveFormat(ArchiveFormat format) {
  return extensionForArchiveFormat(format);
}

String _archiveBaseName(String path) {
  return archiveBaseName(path);
}

int _compressionLevelForTask(TransferTask task) {
  return task.archiveCompressionLevel ?? 6;
}

TransferExecutor createTransferExecutor() {
  return const LocalTransferExecutor();
}

enum _ArchiveCodec { gzip, bzip2, xz }
