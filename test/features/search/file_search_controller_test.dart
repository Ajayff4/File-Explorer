import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/search/data/repositories/in_memory_search_index_store.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches names and paths with folders sorted first', () async {
    final repository = _TreeStorageRepository({
      '/root': [
        _folder('Reports', '/root/Reports'),
        _file('report.txt', '/root/report.txt'),
      ],
      '/root/Reports': [
        _file('annual.txt', '/root/Reports/annual.txt'),
      ],
    });
    final controller = FileSearchController(repository);

    await controller.searchNow(query: 'report', rootPath: '/root');

    expect(controller.state.isSearching, isFalse);
    expect(
      controller.state.results.map((result) => result.entry.path),
      [
        '/root/Reports',
        '/root/report.txt',
        '/root/Reports/annual.txt',
      ],
    );
  });

  test('empty query clears results', () async {
    final repository = _TreeStorageRepository({
      '/root': [_file('report.txt', '/root/report.txt')],
    });
    final controller = FileSearchController(repository);

    await controller.searchNow(query: 'report', rootPath: '/root');
    await controller.searchNow(query: '', rootPath: '/root');

    expect(controller.state.results, isEmpty);
    expect(controller.state.isSearching, isFalse);
  });

  test('filters results by selected file types', () async {
    final repository = _TreeStorageRepository({
      '/root': [
        _folder('Docs', '/root/Docs'),
        _file('report.txt', '/root/report.txt'),
        _image('report.png', '/root/report.png'),
      ],
    });
    final controller = FileSearchController(repository);

    await controller.searchNow(query: 'report', rootPath: '/root');
    await controller.setFilteredTypes(
      filteredTypes: const {FileSystemEntryType.document},
      rootPath: '/root',
    );

    expect(
      controller.state.results.map((result) => result.entry.path),
      ['/root/report.txt'],
    );
  });

  test('uses provided root path as search scope', () async {
    final repository = _TreeStorageRepository({
      '/current': [_file('report.txt', '/current/report.txt')],
      '/storage': [_file('report.txt', '/storage/report.txt')],
    });
    final controller = FileSearchController(repository);

    await controller.searchNow(query: 'report', rootPath: '/storage');

    expect(repository.listedPaths, ['/storage']);
    expect(controller.state.rootPath, '/storage');
    expect(controller.state.results.single.entry.path, '/storage/report.txt');
  });

  test('builds index once and reuses it for later searches', () async {
    final repository = _TreeStorageRepository({
      '/root': [
        _folder('Reports', '/root/Reports'),
        _file('report.txt', '/root/report.txt'),
      ],
      '/root/Reports': [
        _file('annual.txt', '/root/Reports/annual.txt'),
      ],
    });
    final indexStore = InMemorySearchIndexStore();
    final controller = FileSearchController(
      repository,
      indexStore: indexStore,
    );

    await controller.searchNow(query: 'report', rootPath: '/root');
    expect(repository.listedPaths, ['/root', '/root/Reports']);

    repository.listedPaths.clear();
    await controller.searchNow(query: 'annual', rootPath: '/root');

    expect(repository.listedPaths, isEmpty);
    expect(
      controller.state.results.map((result) => result.entry.path),
      ['/root/Reports/annual.txt'],
    );
  });

  test('slow stale search cannot replace newer results', () async {
    final repository = _DelayedStorageRepository();
    final controller = FileSearchController(repository);

    final firstSearch = controller.searchNow(query: 'apple', rootPath: '/root');
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final secondSearch =
        controller.searchNow(query: 'banana', rootPath: '/root');

    await Future.wait([firstSearch, secondSearch]);

    expect(
      controller.state.results.map((result) => result.entry.name),
      ['banana.txt'],
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

FileSystemEntry _file(String name, String path) {
  return FileSystemEntry(
    name: name,
    path: path,
    type: FileSystemEntryType.document,
    modifiedAt: DateTime(2026),
    sizeBytes: 42,
  );
}

FileSystemEntry _image(String name, String path) {
  return FileSystemEntry(
    name: name,
    path: path,
    type: FileSystemEntryType.image,
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
}

class _DelayedStorageRepository extends _TreeStorageRepository {
  _DelayedStorageRepository()
      : super({
          '/root': [
            _file('apple.txt', '/root/apple.txt'),
            _file('banana.txt', '/root/banana.txt'),
          ],
        });

  int _callCount = 0;

  @override
  Future<DirectoryListing> listDirectory(String path) async {
    _callCount += 1;
    if (_callCount == 1) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return super.listDirectory(path);
  }
}
