import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_store_media_library_repository.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/media_store');
  const platform = MediaStorePlatform(channel: channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mockMediaRows(Map<String, List<Map<String, Object?>>> rowsByType) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'queryMedia') {
        final type = call.arguments['type'] as String?;
        return rowsByType[type] ?? const <Map<String, Object?>>[];
      }
      return null;
    });
  }

  group('MediaStorePlatform', () {
    test('maps media rows from the platform channel', () async {
      mockMediaRows({
        'image': [
          {
            'path': '/storage/emulated/0/DCIM/Camera/photo.jpg',
            'name': 'photo.jpg',
            'sizeBytes': 1024,
            'modifiedAtMs': 1700000000000,
          },
          {
            'path': '/storage/emulated/0/Pictures/size_as_string.png',
            'name': 'size_as_string.png',
            'sizeBytes': '2048',
            'modifiedAtMs': '1700000001000',
          },
        ],
      });

      final items = await platform.queryMedia(MediaStoreMediaType.image);

      expect(items, hasLength(2));
      expect(items.first.path, '/storage/emulated/0/DCIM/Camera/photo.jpg');
      expect(items.first.name, 'photo.jpg');
      expect(items.first.sizeBytes, 1024);
      expect(
        items.first.modifiedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(items[1].sizeBytes, 2048);
    });

    test('drops rows with an empty path', () async {
      mockMediaRows({
        'audio': [
          {'path': '', 'name': 'ghost.mp3', 'sizeBytes': 1, 'modifiedAtMs': 0},
        ],
      });

      expect(await platform.queryMedia(MediaStoreMediaType.audio), isEmpty);
    });

    test('countMedia returns the count from the channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'countMedia') {
          expect(call.arguments['type'], 'video');
          expect(call.arguments['path'], '/storage/emulated/0/Movies');
          return 37;
        }
        return null;
      });

      expect(
        await platform.countMedia(
          MediaStoreMediaType.video,
          rootPath: '/storage/emulated/0/Movies',
        ),
        37,
      );
    });

    test('countMedia returns zero when the channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      expect(
        await platform.countMedia(
          MediaStoreMediaType.image,
          rootPath: '/storage/emulated/0/DCIM',
        ),
        0,
      );
    });

    test('countMedia throws so callers can fall back to the walker', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'count_failed');
      });

      await expectLater(
        platform.countMedia(
          MediaStoreMediaType.image,
          rootPath: '/storage/emulated/0/DCIM',
        ),
        throwsA(isA<PlatformException>()),
      );
    });

    test('queryFiles maps rows under the requested path', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'queryFiles') {
          expect(call.arguments['path'], '/storage/emulated/0/Download');
          return [
            {
              'path': '/storage/emulated/0/Download/report.pdf',
              'name': 'report.pdf',
              'sizeBytes': 10,
              'modifiedAtMs': 1700000000000,
            },
            {
              'path': '/storage/emulated/0/Download/app.apk',
              'name': 'app.apk',
              'sizeBytes': 20,
              'modifiedAtMs': 1700000001000,
            },
          ];
        }
        return null;
      });

      final items =
          await platform.queryFiles(rootPath: '/storage/emulated/0/Download');

      expect(items, hasLength(2));
      expect(items.first.path, '/storage/emulated/0/Download/report.pdf');
      expect(items[1].name, 'app.apk');
      expect(items[1].sizeBytes, 20);
    });

    test('queryFiles returns empty when the channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      expect(
        await platform.queryFiles(rootPath: '/storage/emulated/0'),
        isEmpty,
      );
    });

    test('queryFiles drops rows with an empty path', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return [
          {'path': '', 'name': 'ghost.txt', 'sizeBytes': 1, 'modifiedAtMs': 0},
          {
            'path': '/storage/emulated/0/doc.txt',
            'name': 'doc.txt',
            'sizeBytes': 2,
            'modifiedAtMs': 0,
          },
        ];
      });

      final items = await platform.queryFiles(rootPath: '/storage/emulated/0');

      expect(items, hasLength(1));
      expect(items.single.path, '/storage/emulated/0/doc.txt');
    });
  });

  group('MediaStoreMediaLibraryRepository', () {
    test('maps rows to search results grouped by parent folder', () async {
      mockMediaRows({
        'image': [
          {
            'path': '/storage/emulated/0/DCIM/Camera/a.jpg',
            'name': 'a.jpg',
            'sizeBytes': 10,
            'modifiedAtMs': 1700000000000,
          },
          {
            'path': '/storage/emulated/0/X/Y/Z/b.jpg',
            'name': 'b.jpg',
            'sizeBytes': 20,
            'modifiedAtMs': 1700000001000,
          },
        ],
      });

      final repository = MediaStoreMediaLibraryRepository(
        platform: platform,
        fallback: _FakeFallbackMediaLibraryRepository(),
      );

      final results = await repository.findFoldersWithMedia(
        rootPath: '/storage/emulated/0',
        type: FileSystemEntryType.image,
      );

      expect(results, hasLength(2));
      expect(results.first.parentPath, '/storage/emulated/0/DCIM/Camera');
      expect(results.first.entry.type, FileSystemEntryType.image);
      expect(results.first.entry.name, 'a.jpg');
      expect(results.first.entry.sizeBytes, 10);
      expect(results[1].parentPath, '/storage/emulated/0/X/Y/Z');
    });

    test('keeps only results under the requested root path', () async {
      mockMediaRows({
        'video': [
          {
            'path': '/storage/emulated/0/Movies/in.mp4',
            'name': 'in.mp4',
            'sizeBytes': 1,
            'modifiedAtMs': 0,
          },
          {
            'path': '/storage/1234-5678/Movies/out.mp4',
            'name': 'out.mp4',
            'sizeBytes': 1,
            'modifiedAtMs': 0,
          },
        ],
      });

      final repository = MediaStoreMediaLibraryRepository(
        platform: platform,
        fallback: _FakeFallbackMediaLibraryRepository(),
      );

      final results = await repository.findFoldersWithMedia(
        rootPath: '/storage/emulated/0',
        type: FileSystemEntryType.video,
      );

      expect(results, hasLength(1));
      expect(results.single.entry.path, '/storage/emulated/0/Movies/in.mp4');
    });

    test('falls back to the walker when the query fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'query_failed');
      });

      final fallback = _FakeFallbackMediaLibraryRepository();
      final repository = MediaStoreMediaLibraryRepository(
        platform: platform,
        fallback: fallback,
      );

      final results = await repository.findFoldersWithMedia(
        rootPath: '/storage/emulated/0',
        type: FileSystemEntryType.image,
      );

      expect(fallback.callCount, 1);
      expect(results, same(fallback.results));
    });

    test('routes document types through MediaStore', () async {
      mockMediaRows({
        'document': [
          {
            'path': '/storage/emulated/0/Download/report.pdf',
            'name': 'report.pdf',
            'sizeBytes': 10,
            'modifiedAtMs': 0,
          },
        ],
      });

      final fallback = _FakeFallbackMediaLibraryRepository();
      final repository = MediaStoreMediaLibraryRepository(
        platform: platform,
        fallback: fallback,
      );

      final results = await repository.findByType(
        rootPath: '/storage/emulated/0',
        type: FileSystemEntryType.document,
      );

      expect(fallback.callCount, 0);
      expect(
          results.single.entry.path, '/storage/emulated/0/Download/report.pdf');
      expect(results.single.entry.type, FileSystemEntryType.document);
    });
  });
}

class _FakeFallbackMediaLibraryRepository implements MediaLibraryRepository {
  int callCount = 0;

  final results = <SearchResult>[
    SearchResult(
      entry: FileSystemEntry(
        name: 'fallback.jpg',
        path: '/storage/emulated/0/fallback.jpg',
        type: FileSystemEntryType.image,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      parentPath: '/storage/emulated/0',
      depth: 0,
    ),
  ];

  @override
  Future<List<SearchResult>> findByType({
    required String rootPath,
    required FileSystemEntryType type,
  }) async {
    callCount += 1;
    return results;
  }

  @override
  Future<List<SearchResult>> findFoldersWithMedia({
    required String rootPath,
    required FileSystemEntryType type,
  }) async {
    callCount += 1;
    return results;
  }
}
