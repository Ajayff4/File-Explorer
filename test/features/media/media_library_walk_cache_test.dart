import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_walk_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one walk serves every type from the cache', () async {
    final repository = _TreeStorageRepository({
      '/root': [
        _entry('photo.jpg', '/root/photo.jpg', FileSystemEntryType.image),
        _entry('report.txt', '/root/report.txt', FileSystemEntryType.document),
        _folder('Docs', '/root/Docs'),
      ],
      '/root/Docs': [
        _entry('note.txt', '/root/Docs/note.txt', FileSystemEntryType.document),
      ],
    });
    final cache = MediaLibraryWalkCache(storageRepository: repository);

    final images = await cache.resultsFor(
      rootPath: '/root',
      type: FileSystemEntryType.image,
    );

    expect(images.map((result) => result.entry.path), ['/root/photo.jpg']);

    repository.listedPaths.clear();
    final documents = await cache.resultsFor(
      rootPath: '/root',
      type: FileSystemEntryType.document,
    );

    expect(repository.listedPaths, isEmpty);
    expect(
      documents.map((result) => result.entry.path).toSet(),
      {'/root/report.txt', '/root/Docs/note.txt'},
    );
  });

  test('re-walks once the ttl expires', () async {
    var now = DateTime(2026);
    final repository = _TreeStorageRepository({
      '/root': [_entry('a.txt', '/root/a.txt', FileSystemEntryType.document)],
    });
    final cache = MediaLibraryWalkCache(
      storageRepository: repository,
      ttl: const Duration(minutes: 5),
      now: () => now,
    );

    await cache.resultsFor(
        rootPath: '/root', type: FileSystemEntryType.document);
    expect(repository.listedPaths, ['/root']);

    now = now.add(const Duration(minutes: 6));
    await cache.resultsFor(
        rootPath: '/root', type: FileSystemEntryType.document);

    expect(repository.listedPaths, ['/root', '/root']);
  });

  test('concurrent callers share a single in-flight walk', () async {
    final repository = _DelayedTreeStorageRepository();
    final cache = MediaLibraryWalkCache(storageRepository: repository);

    await Future.wait([
      cache.resultsFor(rootPath: '/root', type: FileSystemEntryType.image),
      cache.resultsFor(rootPath: '/root', type: FileSystemEntryType.document),
    ]);

    expect(repository.listedPaths.toSet(), {'/root', '/root/Docs'});
  });

  test('invalidate forces a re-walk', () async {
    final repository = _TreeStorageRepository({
      '/root': [_entry('a.txt', '/root/a.txt', FileSystemEntryType.document)],
    });
    final cache = MediaLibraryWalkCache(storageRepository: repository);

    await cache.resultsFor(
        rootPath: '/root', type: FileSystemEntryType.document);
    cache.invalidate('/root');
    await cache.resultsFor(
        rootPath: '/root', type: FileSystemEntryType.document);

    expect(repository.listedPaths, ['/root', '/root']);
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

class _DelayedTreeStorageRepository extends _TreeStorageRepository {
  _DelayedTreeStorageRepository()
      : super({
          '/root': [
            _entry('photo.jpg', '/root/photo.jpg', FileSystemEntryType.image),
            _folder('Docs', '/root/Docs'),
          ],
          '/root/Docs': [
            _entry('note.txt', '/root/Docs/note.txt',
                FileSystemEntryType.document),
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
