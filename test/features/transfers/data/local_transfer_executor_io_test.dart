import 'dart:io';

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
}

TransferTask _task({
  required TransferOperation operation,
  required String sourcePath,
  String? destinationPath,
  int? totalBytes,
  ConflictPolicy conflictPolicy = ConflictPolicy.ask,
}) {
  final now = DateTime(2026);
  return TransferTask(
    id: 'test-task',
    operation: operation,
    sourcePaths: [sourcePath],
    displayName: sourcePath,
    status: TransferTaskStatus.queued,
    createdAt: now,
    updatedAt: now,
    destinationPath: destinationPath,
    progress: TransferProgress(totalBytes: totalBytes),
    conflictPolicy: conflictPolicy,
  );
}
