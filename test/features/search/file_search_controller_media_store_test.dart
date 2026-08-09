import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/search/data/repositories/in_memory_search_index_store.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/search_media_store');
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

  test('type-only browse merges MediaStore-backed types', () async {
    mockMediaRows({
      'image': [
        {
          'path': '/root/Pictures/photo.jpg',
          'name': 'photo.jpg',
          'sizeBytes': 5,
          'modifiedAtMs': 0,
        },
      ],
      'document': [
        {
          'path': '/root/Docs/report.txt',
          'name': 'report.txt',
          'sizeBytes': 5,
          'modifiedAtMs': 0,
        },
      ],
    });
    final repository = _TreeStorageRepository({
      '/root': [_folder('Pictures', '/root/Pictures')],
      '/root/Pictures': const [],
    });
    final controller = FileSearchController(repository, mediaStore: platform);

    await controller.setFilteredTypes(
      filteredTypes: const {
        FileSystemEntryType.image,
        FileSystemEntryType.document,
      },
      rootPath: '/root',
    );

    expect(
      controller.state.results.map((result) => result.entry.path).toSet(),
      {'/root/Pictures/photo.jpg', '/root/Docs/report.txt'},
    );
  });

  test('type-only browse keeps results under the requested root', () async {
    mockMediaRows({
      'video': [
        {
          'path': '/root/Movies/in.mp4',
          'name': 'in.mp4',
          'sizeBytes': 1,
          'modifiedAtMs': 0,
        },
        {
          'path': '/other/Movies/out.mp4',
          'name': 'out.mp4',
          'sizeBytes': 1,
          'modifiedAtMs': 0,
        },
      ],
    });
    final controller = FileSearchController(
      _TreeStorageRepository(const {}),
      mediaStore: platform,
    );

    await controller.setFilteredTypes(
      filteredTypes: const {FileSystemEntryType.video},
      rootPath: '/root',
    );

    expect(
      controller.state.results.map((result) => result.entry.path),
      ['/root/Movies/in.mp4'],
    );
  });

  test('type-only browse falls back to the walker when MediaStore fails',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'query_failed');
    });
    final repository = _TreeStorageRepository({
      '/root': [_folder('Pictures', '/root/Pictures')],
      '/root/Pictures': [
        _entry(
            'photo.png', '/root/Pictures/photo.png', FileSystemEntryType.image),
      ],
    });
    final controller = FileSearchController(repository, mediaStore: platform);

    await controller.setFilteredTypes(
      filteredTypes: const {FileSystemEntryType.image},
      rootPath: '/root',
    );

    expect(
      controller.state.results.map((result) => result.entry.path),
      ['/root/Pictures/photo.png'],
    );
  });

  test('index build seeds media rows the walk never sees', () async {
    mockMediaRows({
      'audio': [
        {
          'path': '/root/Music/seeded.mp3',
          'name': 'seeded.mp3',
          'sizeBytes': 3,
          'modifiedAtMs': 0,
        },
      ],
    });
    final repository = _TreeStorageRepository({
      '/root': [
        _entry('report.txt', '/root/report.txt', FileSystemEntryType.document),
      ],
    });
    final controller = FileSearchController(
      repository,
      indexStore: InMemorySearchIndexStore(),
      mediaStore: platform,
    );

    await controller.searchNow(query: 'seeded', rootPath: '/root');

    expect(
      controller.state.results.map((result) => result.entry.path),
      ['/root/Music/seeded.mp3'],
    );
  });

  test('index seeding does not duplicate media files also found by the walk',
      () async {
    mockMediaRows({
      'image': [
        {
          'path': '/root/Pictures/photo.jpg',
          'name': 'photo.jpg',
          'sizeBytes': 5,
          'modifiedAtMs': 0,
        },
      ],
    });
    final repository = _TreeStorageRepository({
      '/root': [_folder('Pictures', '/root/Pictures')],
      '/root/Pictures': [
        _entry(
            'photo.jpg', '/root/Pictures/photo.jpg', FileSystemEntryType.image),
      ],
    });
    final controller = FileSearchController(
      repository,
      indexStore: InMemorySearchIndexStore(),
      mediaStore: platform,
    );

    await controller.searchNow(query: 'photo', rootPath: '/root');

    expect(
      controller.state.results.map((result) => result.entry.path),
      ['/root/Pictures/photo.jpg'],
    );
  });

  test('folders stay indexed regardless of media row count', () async {
    final mediaRows = [
      for (var i = 0; i < 3000; i++)
        {
          'path': '/root/Pictures/img$i.jpg',
          'name': 'img$i.jpg',
          'sizeBytes': i,
          'modifiedAtMs': 0,
        },
    ];
    mockMediaRows({'image': mediaRows});
    final repository = _TreeStorageRepository({
      '/root': [
        _folder('Downloads', '/root/Downloads'),
        _folder('Pictures', '/root/Pictures'),
      ],
      '/root/Downloads': [
        _entry(
            'report.pdf', '/root/Downloads/report.pdf', FileSystemEntryType.document),
      ],
    });
    final controller = FileSearchController(
      repository,
      indexStore: InMemorySearchIndexStore(),
      mediaStore: platform,
    );

    await controller.searchNow(query: 'Downloads', rootPath: '/root');

    expect(
      controller.state.results.map((result) => result.entry.path),
      contains('/root/Downloads'),
    );
  });
}

FileSystemEntry _folder(String name, String path) {
  return FileSystemEntry(
    name: name,
    path: path,
    type: FileSystemEntryType.folder,
    modifiedAt: DateTime(2026),
    childrenCount: 1,
  );
}

FileSystemEntry _entry(
  String name,
  String path,
  FileSystemEntryType type,
) {
  return FileSystemEntry(
    name: name,
    path: path,
    type: type,
    modifiedAt: DateTime(2026),
    sizeBytes: 42,
  );
}

class _TreeStorageRepository implements StorageRepository {
  _TreeStorageRepository(this._entriesByPath);

  final Map<String, List<FileSystemEntry>> _entriesByPath;
  final listedPaths = <String>[];

  @override
  Future<List<StorageVolume>> getStorageVolumes() async {
    return const [];
  }

  @override
  Future<StorageSummary> getPrimaryStorageSummary() async {
    return const StorageSummary(label: 'Storage', usedBytes: 0, totalBytes: 1);
  }

  @override
  Future<DirectoryListing> listDirectory(String path) async {
    listedPaths.add(path);
    return DirectoryListing(
      path: path,
      entries: _entriesByPath[path] ?? const [],
    );
  }

  @override
  Future<Map<FileSystemEntryType, int>> countEntriesByType(
    String rootPath,
  ) async {
    return const {};
  }

  @override
  Future<bool> createFolder(String path) async {
    return true;
  }

  @override
  Future<bool> createFile(String path, {String content = ''}) async {
    return true;
  }
}
