import 'dart:io';
import 'dart:typed_data';

import 'package:file_explorer/features/encryption/data/encryption_repository.dart';
import 'package:file_explorer/features/encryption/data/encryption_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = EncryptionService();

  group('EncryptionService', () {
    test('round-trips with a visible name', () async {
      final content = Uint8List.fromList('secret data'.codeUnits);
      final session = await service.openSession('hunter2');

      final container = await service.encrypt(
        content,
        session,
        'note.txt',
        encryptName: false,
      );

      final decrypted = await service.decrypt(container, 'hunter2');
      expect(decrypted.name, 'note.txt');
      expect(decrypted.bytes, content);
    });

    test('round-trips with an encrypted name', () async {
      final content = Uint8List.fromList('secret data'.codeUnits);
      final session = await service.openSession('hunter2');

      final container = await service.encrypt(
        content,
        session,
        'report.docx',
        encryptName: true,
      );

      final decrypted = await service.decrypt(container, 'hunter2');
      expect(decrypted.name, 'report.docx');
      expect(decrypted.bytes, content);
    });

    test('rejects a wrong password', () async {
      final content = Uint8List.fromList('secret data'.codeUnits);
      final session = await service.openSession('hunter2');
      final container = await service.encrypt(
        content,
        session,
        'note.txt',
        encryptName: false,
      );

      expect(
        () => service.decrypt(container, 'wrong'),
        throwsA(isA<WrongPasswordException>()),
      );
    });

    test('rejects a non-FF4 container', () async {
      expect(
        () => service.decrypt(Uint8List.fromList('junk'.codeUnits), 'pw'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('EncryptionRepository', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('encryption_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('encrypts files in place and decrypts them back', () async {
      final repo = EncryptionRepository(service);
      final source = File('${tempDir.path}/note.txt');
      await source.writeAsString('hello world');

      final result = await repo.encryptPaths(
        [source.path],
        password: 'hunter2',
        encryptName: false,
      );
      expect(result.encryptedCount, 1);
      expect(await source.exists(), isFalse);

      final container = File('${source.path}.ff4');
      expect(await container.exists(), isTrue);

      final restored = await repo.decryptPath(container.path, 'hunter2');
      expect(restored, source.path);
      expect(await source.exists(), isTrue);
      expect(await source.readAsString(), 'hello world');
      expect(await container.exists(), isFalse);
    });

    test('encrypts a folder recursively, one .ff4 per file', () async {
      final repo = EncryptionRepository(service);
      final folder = Directory('${tempDir.path}/docs');
      await folder.create();
      await File('${folder.path}/a.txt').writeAsString('a');
      await Directory('${folder.path}/sub').create();
      await File('${folder.path}/sub/b.txt').writeAsString('b');

      final result = await repo.encryptPaths(
        [folder.path],
        password: 'hunter2',
        encryptName: true,
      );
      expect(result.encryptedCount, 2);
      expect(await File('${folder.path}/a.txt').exists(), isFalse);
      expect(await File('${folder.path}/sub/b.txt').exists(), isFalse);

      final containers = await folder
          .list(recursive: true)
          .where((e) => e.path.endsWith('.ff4'))
          .toList();
      expect(containers.length, 2);
    });

    test('keeps original name when name is visible, random id when hidden', () async {
      final repo = EncryptionRepository(service);
      final source = File('${tempDir.path}/report.txt');
      await source.writeAsString('data');

      await repo.encryptPaths([source.path], password: 'pw', encryptName: false);
      expect(await File('${source.path}.ff4').exists(), isTrue);

      final secret = File('${tempDir.path}/secret.txt');
      await secret.writeAsString('data');
      await repo.encryptPaths([secret.path], password: 'pw', encryptName: true);

      final names = await tempDir
          .list()
          .where((e) => e.path.endsWith('.ff4'))
          .map((e) => e.path.split('/').last)
          .toList();
      expect(names, contains('report.txt.ff4'));
      final randomName = names.firstWhere((n) => n != 'report.txt.ff4');
      expect(RegExp(r'^[0-9a-f]{32}\.ff4$').hasMatch(randomName), isTrue);
    });
  });
}
