import 'dart:io';

import 'package:file_explorer/features/recycle_bin/data/recycle_bin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recycle_bin_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('moves to trash, lists, restores, and empties', () async {
    const repo = RecycleBinRepository();
    final source = File('${tempDir.path}/note.txt');
    await source.writeAsString('hello');

    final trashRoot = '${tempDir.path}/.recycle_bin';
    final item = await repo.moveToTrashTo(source.path, trashRoot);

    expect(await source.exists(), isFalse);
    expect(await File(item.trashPath).exists(), isTrue);
    expect(item.originalPath, source.path);

    final listed = await repo.listTrash(trashRoot);
    expect(listed.length, 1);
    expect(listed.first.name, 'note.txt');

    await repo.restore(listed.first);
    expect(await source.exists(), isTrue);
    expect(await source.readAsString(), 'hello');
    expect(await repo.listTrash(trashRoot), isEmpty);
  });

  test('permanently deletes a trashed item', () async {
    const repo = RecycleBinRepository();
    final source = File('${tempDir.path}/gone.txt');
    await source.writeAsString('bye');

    final trashRoot = '${tempDir.path}/.recycle_bin';
    final item = await repo.moveToTrashTo(source.path, trashRoot);
    await repo.deletePermanently(item);

    expect(await File(item.trashPath).exists(), isFalse);
    expect(await repo.listTrash(trashRoot), isEmpty);
  });

  test('emptyTrash removes everything', () async {
    const repo = RecycleBinRepository();
    final trashRoot = '${tempDir.path}/.recycle_bin';
    await repo.moveToTrashTo(
      (await File('${tempDir.path}/a.txt').create()).path,
      trashRoot,
    );
    await repo.moveToTrashTo(
      (await File('${tempDir.path}/b.txt').create()).path,
      trashRoot,
    );

    await repo.emptyTrash(trashRoot);
    expect(await Directory(trashRoot).exists(), isFalse);
  });
}
