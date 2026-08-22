import 'dart:io';
import 'package:file_explorer/features/analyzer/data/storage_analyzer_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scan aggregates', () async {
    final dir = Directory.systemTemp.createTempSync('scanprobe');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/a.txt').writeAsStringSync('x' * 1024);
    File('${dir.path}/b.jpg').writeAsStringSync('y' * 2048);
    Directory('${dir.path}/sub').createSync();
    File('${dir.path}/sub/c.mp4').writeAsStringSync('z' * 4096);
    final result = await scanStorage(dir.path);
    expect(result.totalBytes, 1024 + 2048 + 4096);
    expect(result.fileCount, 3);
    expect(result.folderCount, 2); // root + sub
    expect(result.files.first.bytes, 4096);
  });
}
