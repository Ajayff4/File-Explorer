import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/search/data/repositories/in_memory_search_index_store.dart';
import 'package:file_explorer/features/search/data/repositories/search_index_store_provider.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/features/search/presentation/controllers/search_index_invalidation_provider.dart';
import 'package:file_explorer/features/transfers/data/repositories/fake_transfer_executor.dart';
import 'package:file_explorer/features/transfers/data/repositories/in_memory_transfer_task_store.dart';
import 'package:file_explorer/features/transfers/data/repositories/transfer_executor_provider.dart';
import 'package:file_explorer/features/transfers/data/repositories/transfer_task_store_provider.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed transfer clears overlapping search indexes', () async {
    final indexStore = InMemorySearchIndexStore();
    await indexStore.replaceIndex(
      rootPath: '/root',
      entries: [
        _entry('/root/file.txt'),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        searchIndexStoreProvider.overrideWithValue(indexStore),
        fileSearchControllerProvider.overrideWith(
          (ref) => FileSearchController(
            _EmptyStorageRepository(),
            mediaStore: null,
          ),
        ),
        transferExecutorProvider
            .overrideWithValue(const FakeTransferExecutor()),
        transferTaskStoreProvider
            .overrideWithValue(InMemoryTransferTaskStore()),
      ],
    );
    addTearDown(container.dispose);

    container.read(searchIndexInvalidationProvider);
    container.read(transferControllerProvider.notifier).queueOperation(
          operation: TransferOperation.delete,
          sourcePaths: const ['/root/file.txt'],
          displayName: 'file.txt',
          totalBytes: 42,
        );
    await _pumpEventQueue();

    expect(await indexStore.hasIndex('/root'), isFalse);
  });

  test('completed transfer re-warms the index it cleared', () async {
    final indexStore = InMemorySearchIndexStore();
    await indexStore.replaceIndex(
      rootPath: '/root',
      entries: [
        _entry('/root/old.txt'),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        searchIndexStoreProvider.overrideWithValue(indexStore),
        fileSearchControllerProvider.overrideWith(
          (ref) => FileSearchController(
            _ReWarmStorageRepository(),
            indexStore: indexStore,
            mediaStore: null,
          ),
        ),
        transferExecutorProvider
            .overrideWithValue(const FakeTransferExecutor()),
        transferTaskStoreProvider
            .overrideWithValue(InMemoryTransferTaskStore()),
      ],
    );
    addTearDown(container.dispose);

    container.read(searchIndexInvalidationProvider);
    container.read(transferControllerProvider.notifier).queueOperation(
          operation: TransferOperation.delete,
          sourcePaths: const ['/root/old.txt'],
          displayName: 'old.txt',
          totalBytes: 42,
        );
    await _pumpEventQueue();
    await _waitForIndex(container, indexStore, '/root');

    expect(await indexStore.hasIndex('/root'), isTrue);
    final results = await indexStore.search(
      rootPath: '/root',
      query: 'old',
      filteredTypes: const {},
    );
    expect(results, isEmpty);
  });
}

Future<void> _waitForIndex(
  ProviderContainer container,
  InMemorySearchIndexStore indexStore,
  String rootPath,
) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (await indexStore.hasIndex(rootPath)) {
      return;
    }
    await _pumpEventQueue();
  }
  fail('Index was not re-warmed after invalidation');
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

SearchResult _entry(String path) {
  final name = path.split('/').last;
  return SearchResult(
    entry: FileSystemEntry(
      name: name,
      path: path,
      type: FileSystemEntryType.document,
      modifiedAt: DateTime(2026),
      sizeBytes: 42,
    ),
    parentPath: path.substring(0, path.lastIndexOf('/')),
    depth: 0,
  );
}

class _EmptyStorageRepository implements StorageRepository {
  @override
  Future<DirectoryListing> listDirectory(String path) async {
    return DirectoryListing(path: path, entries: const []);
  }

  @override
  Future<List<StorageVolume>> getStorageVolumes() async => const [];

  @override
  Future<StorageSummary> getPrimaryStorageSummary() async {
    return const StorageSummary(label: 'Storage', usedBytes: 0, totalBytes: 1);
  }

  @override
  Future<Map<FileSystemEntryType, int>> countEntriesByType(
    String rootPath,
  ) async {
    return const {};
  }

  @override
  Future<bool> createFolder(String path) async => true;

  @override
  Future<bool> createFile(String path, {String content = ''}) async => true;
}

class _ReWarmStorageRepository extends _EmptyStorageRepository {
  @override
  Future<DirectoryListing> listDirectory(String path) async {
    return DirectoryListing(
      path: path,
      entries: [
        FileSystemEntry(
          name: 'new.txt',
          path: '/root/new.txt',
          type: FileSystemEntryType.document,
          modifiedAt: DateTime(2026),
          sizeBytes: 42,
        ),
      ],
    );
  }
}
