import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_explorer/features/zip/data/repositories/local_zip_repository_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String archivePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_explorer_zip_');
    archivePath = '${tempDir.path}/sample.zip';
    final archive = Archive();
    archive.addFile(ArchiveFile.string('Documents/Invoice_Q3.pdf', 'pdf data'));
    archive.addFile(ArchiveFile.string('Documents/notes.txt', 'hello from zip'));
    archive.addFile(ArchiveFile.string('Photos/IMG.jpg', 'image bytes'));
    archive.addFile(ArchiveFile.string('backup_manifest.json', '{}'));
    final bytes = ZipEncoder().encode(archive);
    await File(archivePath).writeAsBytes(Uint8List.fromList(bytes));
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  const repository = LocalZipRepository();

  test('lists root entries with folders first', () async {
    final listing = await repository.listDirectory(archivePath);
    expect(listing.directoryPath, '');
    final names = listing.entries.map((e) => e.name).toList();
    expect(names, ['Documents', 'Photos', 'backup_manifest.json']);

    final documents = listing.entries.first;
    expect(documents.isFolder, isTrue);
    expect(documents.childrenCount, 2);

    final manifest = listing.entries.last;
    expect(manifest.isFolder, isFalse);
    expect(manifest.sizeBytes, greaterThan(0));
  });

  test('lists entries inside a subfolder', () async {
    final listing = await repository.listDirectory(archivePath, directoryPath: 'Documents');
    expect(listing.directoryPath, 'Documents');
    final names = listing.entries.map((e) => e.name).toList();
    expect(names, ['Invoice_Q3.pdf', 'notes.txt']);
    expect(listing.entries.every((e) => !e.isFolder), isTrue);
  });

  test('returns empty for unknown folders', () async {
    final listing =
        await repository.listDirectory(archivePath, directoryPath: 'Missing');
    expect(listing.entries, isEmpty);
  });

  test('reads entry content', () async {
    final bytes = await repository.readEntry(archivePath, 'Documents/notes.txt');
    expect(utf8.decode(bytes!), 'hello from zip');
  });

  test('returns null for missing entry', () async {
    final bytes = await repository.readEntry(archivePath, 'Missing/file.txt');
    expect(bytes, isNull);
  });
}
