import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_explorer/features/transfers/data/repositories/local_transfer_executor_io.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_explorer_transfer_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('renames a file', () async {
    final source = File('${tempDir.path}/old.txt');
    await source.writeAsString('hello');
    final destination = '${tempDir.path}/new.txt';

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.rename,
        sourcePath: source.path,
        destinationPath: destination,
      ),
      onProgress: (_) {},
    );

    expect(await source.exists(), isFalse);
    expect(await File(destination).readAsString(), 'hello');
  });

  test('deletes a directory recursively', () async {
    final sourceDir = Directory('${tempDir.path}/folder');
    await sourceDir.create();
    await File('${sourceDir.path}/child.txt').writeAsString('hello');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.delete,
        sourcePath: sourceDir.path,
      ),
      onProgress: (_) {},
    );

    expect(await sourceDir.exists(), isFalse);
  });

  test('copies a file into destination directory with progress', () async {
    final source = File('${tempDir.path}/source.txt');
    await source.writeAsString('hello');
    final destinationDir = Directory('${tempDir.path}/destination');
    await destinationDir.create();
    final progress = <TransferProgress>[];

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.copy,
        sourcePath: source.path,
        destinationPath: destinationDir.path,
        totalBytes: 5,
      ),
      onProgress: progress.add,
    );

    expect(await source.exists(), isTrue);
    expect(
      await File('${destinationDir.path}/source.txt').readAsString(),
      'hello',
    );
    expect(progress.last.transferredBytes, 5);
  });

  test('asks when destination exists by default', () async {
    final source = File('${tempDir.path}/source.txt');
    await source.writeAsString('hello');
    final destination = File('${tempDir.path}/existing.txt');
    await destination.writeAsString('old');

    expect(
      () => const LocalTransferExecutor().execute(
        _task(
          operation: TransferOperation.rename,
          sourcePath: source.path,
          destinationPath: destination.path,
        ),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TransferExecutionException>().having(
          (error) => error.code,
          'code',
          TransferFailureCode.destinationExists,
        ),
      ),
    );
  });

  test('overwrites existing destination', () async {
    final source = File('${tempDir.path}/source.txt');
    await source.writeAsString('new');
    final destination = File('${tempDir.path}/existing.txt');
    await destination.writeAsString('old');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.rename,
        sourcePath: source.path,
        destinationPath: destination.path,
        conflictPolicy: ConflictPolicy.overwrite,
      ),
      onProgress: (_) {},
    );

    expect(await source.exists(), isFalse);
    expect(await destination.readAsString(), 'new');
  });

  test('skips existing destination', () async {
    final source = File('${tempDir.path}/source.txt');
    await source.writeAsString('new');
    final destination = File('${tempDir.path}/existing.txt');
    await destination.writeAsString('old');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.rename,
        sourcePath: source.path,
        destinationPath: destination.path,
        conflictPolicy: ConflictPolicy.skip,
      ),
      onProgress: (_) {},
    );

    expect(await source.readAsString(), 'new');
    expect(await destination.readAsString(), 'old');
  });

  test('keeps both by renaming destination candidate', () async {
    final source = File('${tempDir.path}/source.txt');
    await source.writeAsString('new');
    final destination = File('${tempDir.path}/existing.txt');
    final renamedDestination = File('${tempDir.path}/existing (1).txt');
    await destination.writeAsString('old');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.rename,
        sourcePath: source.path,
        destinationPath: destination.path,
        conflictPolicy: ConflictPolicy.rename,
      ),
      onProgress: (_) {},
    );

    expect(await source.exists(), isFalse);
    expect(await destination.readAsString(), 'old');
    expect(await renamedDestination.readAsString(), 'new');
  });

  test('compresses selected files into one zip', () async {
    final first = File('${tempDir.path}/first.txt');
    final folder = Directory('${tempDir.path}/docs');
    final nested = File('${folder.path}/second.txt');
    await folder.create();
    await first.writeAsString('one');
    await nested.writeAsString('two');
    final destination = '${tempDir.path}/bundle.zip';

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.compressArchive,
        sourcePaths: [first.path, folder.path],
        destinationPath: destination,
      ),
      onProgress: (_) {},
    );

    expect(await File(destination).exists(), isTrue);

    final extractDir = Directory('${tempDir.path}/extracted');
    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.extractArchive,
        sourcePath: destination,
        destinationPath: extractDir.path,
        conflictPolicy: ConflictPolicy.overwrite,
      ),
      onProgress: (_) {},
    );

    expect(await File('${extractDir.path}/first.txt').readAsString(), 'one');
    expect(
        await File('${extractDir.path}/docs/second.txt').readAsString(), 'two');
  });

  test('extracts zip files into the destination directory', () async {
    final source = File('${tempDir.path}/note.txt');
    final zip = '${tempDir.path}/note.zip';
    await source.writeAsString('hello');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.compressArchive,
        sourcePath: source.path,
        destinationPath: zip,
      ),
      onProgress: (_) {},
    );

    await source.delete();

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.extractArchive,
        sourcePath: zip,
      ),
      onProgress: (_) {},
    );

    expect(await source.readAsString(), 'hello');
  });

  test('compresses and extracts password protected zip files', () async {
    final source = File('${tempDir.path}/secret.txt');
    final zip = '${tempDir.path}/secret.zip';
    await source.writeAsString('hidden');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.compressArchive,
        sourcePath: source.path,
        destinationPath: zip,
        archivePassword: 'pass123',
      ),
      onProgress: (_) {},
    );

    expect(await File(zip).exists(), isTrue);
    await source.delete();

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.extractArchive,
        sourcePath: zip,
        archivePassword: 'pass123',
      ),
      onProgress: (_) {},
    );

    expect(
      await source.readAsString(),
      'hidden',
    );
  });

  test('rejects password protected zip files with the wrong password',
      () async {
    final source = File('${tempDir.path}/secret.txt');
    final zip = '${tempDir.path}/secret.zip';
    await source.writeAsString('hidden');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.compressArchive,
        sourcePath: source.path,
        destinationPath: zip,
        archivePassword: 'pass123',
      ),
      onProgress: (_) {},
    );

    await source.delete();

    expect(
      () => const LocalTransferExecutor().execute(
        _task(
          operation: TransferOperation.extractArchive,
          sourcePath: zip,
          archivePassword: 'wrong',
        ),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TransferExecutionException>().having(
          (error) => error.message,
          'message',
          contains('enter the ZIP password'),
        ),
      ),
    );
  });

  test('rejects password protected zip files without a password', () async {
    final source = File('${tempDir.path}/secret.txt');
    final zip = '${tempDir.path}/secret.zip';
    await source.writeAsString('hidden');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.compressArchive,
        sourcePath: source.path,
        destinationPath: zip,
        archivePassword: 'pass123',
      ),
      onProgress: (_) {},
    );

    await source.delete();

    expect(
      () => const LocalTransferExecutor().execute(
        _task(
          operation: TransferOperation.extractArchive,
          sourcePath: zip,
        ),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TransferExecutionException>().having(
          (error) => error.message,
          'message',
          contains('enter the ZIP password'),
        ),
      ),
    );
  });

  test('compresses and extracts a single file with gzip', () async {
    final source = File('${tempDir.path}/note.txt');
    final gzip = '${tempDir.path}/note.txt.gz';
    await source.writeAsString('hello gzip');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.compressArchive,
        sourcePath: source.path,
        destinationPath: gzip,
      ),
      onProgress: (_) {},
    );

    expect(await File(gzip).exists(), isTrue);
    await source.delete();

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.extractArchive,
        sourcePath: gzip,
      ),
      onProgress: (_) {},
    );

    expect(await source.readAsString(), 'hello gzip');
  });

  test('compresses and extracts a directory with tar gzip', () async {
    final sourceDir = Directory('${tempDir.path}/docs');
    final nested = File('${sourceDir.path}/nested/second.txt');
    final tarGzip = '${tempDir.path}/docs.tar.gz';
    await nested.parent.create(recursive: true);
    await nested.writeAsString('hello tar gzip');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.compressArchive,
        sourcePath: sourceDir.path,
        destinationPath: tarGzip,
      ),
      onProgress: (_) {},
    );

    expect(await File(tarGzip).exists(), isTrue);
    await sourceDir.delete(recursive: true);

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.extractArchive,
        sourcePath: tarGzip,
      ),
      onProgress: (_) {},
    );

    expect(
      await File('${tempDir.path}/nested/second.txt').readAsString(),
      'hello tar gzip',
    );
  });

  test('compresses and extracts a directory with tar', () async {
    final sourceDir = Directory('${tempDir.path}/plain');
    final nested = File('${sourceDir.path}/nested/third.txt');
    final tar = '${tempDir.path}/plain.tar';
    await nested.parent.create(recursive: true);
    await nested.writeAsString('hello tar');

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.compressArchive,
        sourcePath: sourceDir.path,
        destinationPath: tar,
      ),
      onProgress: (_) {},
    );

    expect(await File(tar).exists(), isTrue);
    await sourceDir.delete(recursive: true);

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.extractArchive,
        sourcePath: tar,
      ),
      onProgress: (_) {},
    );

    expect(
      await File('${tempDir.path}/nested/third.txt').readAsString(),
      'hello tar',
    );
  });

  test('extracts a tar.bz2 archive built from the archive package', () async {
    final archiveBytes = TarEncoder().encode(_tarArchive());
    final sourcePath = '${tempDir.path}/bundle.tar.bz2';
    await File(sourcePath).writeAsBytes(BZip2Encoder().encode(archiveBytes));

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.extractArchive,
        sourcePath: sourcePath,
      ),
      onProgress: (_) {},
    );

    expect(
      await File('${tempDir.path}/nested/bz2.txt').readAsString(),
      'hello bz2',
    );
  });

  test('extracts a tar.xz archive built from the archive package', () async {
    final archiveBytes = TarEncoder().encode(_tarArchive());
    final sourcePath = '${tempDir.path}/bundle.tar.xz';
    await File(sourcePath).writeAsBytes(XZEncoder().encode(archiveBytes));

    await const LocalTransferExecutor().execute(
      _task(
        operation: TransferOperation.extractArchive,
        sourcePath: sourcePath,
      ),
      onProgress: (_) {},
    );

    expect(
      await File('${tempDir.path}/nested/xz.txt').readAsString(),
      'hello xz',
    );
  });
}

Archive _tarArchive() {
  final archive = Archive();
  archive.addFile(ArchiveFile.string('nested/bz2.txt', 'hello bz2'));
  archive.addFile(ArchiveFile.string('nested/xz.txt', 'hello xz'));
  return archive;
}

TransferTask _task({
  required TransferOperation operation,
  String? sourcePath,
  List<String>? sourcePaths,
  String? destinationPath,
  int? totalBytes,
  ConflictPolicy conflictPolicy = ConflictPolicy.ask,
  String? archivePassword,
}) {
  final paths = sourcePaths ?? [sourcePath!];
  final now = DateTime(2026);
  return TransferTask(
    id: 'test-task',
    operation: operation,
    sourcePaths: paths,
    displayName: paths.join(', '),
    status: TransferTaskStatus.queued,
    createdAt: now,
    updatedAt: now,
    destinationPath: destinationPath,
    progress: TransferProgress(totalBytes: totalBytes),
    conflictPolicy: conflictPolicy,
    archivePassword: archivePassword,
  );
}
