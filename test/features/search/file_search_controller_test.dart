import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
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

class _TreeStorageRepository implements StorageRepository {
  const _TreeStorageRepository(this._entriesByPath);

  final Map<String, List<FileSystemEntry>> _entriesByPath;

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
