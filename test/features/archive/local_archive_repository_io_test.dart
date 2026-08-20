import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_explorer/features/archive/data/repositories/local_archive_repository_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  final repository = const LocalArchiveRepository();

  Archive buildZipArchive() {
    final archive = Archive();
    archive.addFile(ArchiveFile.string('Documents/Invoice_Q3.pdf', 'pdf data'));
    archive
        .addFile(ArchiveFile.string('Documents/notes.txt', 'hello from zip'));
    archive.addFile(ArchiveFile.string('Photos/IMG.jpg', 'image bytes'));
    archive.addFile(ArchiveFile.string('backup_manifest.json', '{}'));
    return archive;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_explorer_archive_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> writeBytes(String relativePath, List<int> bytes) async {
    final path = '${tempDir.path}/$relativePath';
    await File(path).writeAsBytes(Uint8List.fromList(bytes));
    return path;
  }

  Future<void> verifyListingFor(Archive archive, String path) async {
    final listing = await repository.listDirectory(path);
    expect(listing.directoryPath, '');
    final names = listing.entries.map((e) => e.name).toList();
    expect(names, ['Documents', 'Photos', 'backup_manifest.json']);

    final documents = listing.entries.first;
    expect(documents.isFolder, isTrue);
    expect(documents.childrenCount, 2);

    final manifest = listing.entries.last;
    expect(manifest.isFolder, isFalse);
    expect(manifest.sizeBytes, greaterThan(0));

    final subListing =
        await repository.listDirectory(path, directoryPath: 'Documents');
    final subNames = subListing.entries.map((e) => e.name).toList();
    expect(subNames, ['Invoice_Q3.pdf', 'notes.txt']);

    final bytes = await repository.readEntry(path, 'Documents/notes.txt');
    expect(utf8.decode(bytes!), 'hello from zip');

    final missing = await repository.readEntry(path, 'Missing/file.txt');
    expect(missing, isNull);
  }

  test('browses and reads zip archives', () async {
    final path = await writeBytes(
      'sample.zip',
      ZipEncoder().encode(buildZipArchive()),
    );
    await verifyListingFor(buildZipArchive(), path);
  });

  test('browses and reads tar archives', () async {
    final path = await writeBytes(
      'sample.tar',
      TarEncoder().encode(buildZipArchive()),
    );
    await verifyListingFor(buildZipArchive(), path);
  });

  test('browses and reads tar.gz archives', () async {
    final tarBytes = TarEncoder().encode(buildZipArchive());
    final path = await writeBytes(
      'sample.tar.gz',
      GZipEncoder().encode(tarBytes),
    );
    await verifyListingFor(buildZipArchive(), path);
  });

  test('browses and reads tar.bz2 archives', () async {
    final tarBytes = TarEncoder().encode(buildZipArchive());
    final path = await writeBytes(
      'sample.tar.bz2',
      BZip2Encoder().encode(tarBytes),
    );
    await verifyListingFor(buildZipArchive(), path);
  });

  test('browses and reads tar.xz archives', () async {
    final tarBytes = TarEncoder().encode(buildZipArchive());
    final path = await writeBytes(
      'sample.tar.xz',
      XZEncoder().encode(tarBytes),
    );
    await verifyListingFor(buildZipArchive(), path);
  });

  test('browses and reads a bare gzip file as a single entry', () async {
    final path = await writeBytes(
      'sample.txt.gz',
      GZipEncoder().encode('hello gzip'.codeUnits),
    );
    final listing = await repository.listDirectory(path);
    expect(listing.entries.length, 1);
    final entry = listing.entries.single;
    expect(entry.name, 'sample.txt');
    expect(entry.isFolder, isFalse);
    expect(entry.sizeBytes, greaterThan(0));

    final bytes = await repository.readEntry(path, 'sample.txt');
    expect(utf8.decode(bytes!), 'hello gzip');

    final missing = await repository.readEntry(path, 'other.txt');
    expect(missing, isNull);
  });

  test('returns empty for unknown folders', () async {
    final path = await writeBytes(
      'sample.zip',
      ZipEncoder().encode(buildZipArchive()),
    );
    final listing =
        await repository.listDirectory(path, directoryPath: 'Missing');
    expect(listing.entries, isEmpty);
  });
}
