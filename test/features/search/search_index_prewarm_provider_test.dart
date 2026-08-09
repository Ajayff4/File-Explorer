import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/recents/data/repositories/in_memory_recent_location_store.dart';
import 'package:file_explorer/features/recents/data/repositories/recent_location_store_provider.dart';
import 'package:file_explorer/features/search/data/repositories/in_memory_search_index_store.dart';
import 'package:file_explorer/features/search/data/repositories/search_index_store_provider.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/features/search/presentation/controllers/search_index_prewarm_provider.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/fake_storage_permission_repository.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prewarms volume roots once browse is available', () async {
    final indexStore = InMemorySearchIndexStore();
    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWithValue(
          const _MultiVolumeStorageRepository(),
        ),
        recentLocationStoreProvider
            .overrideWithValue(InMemoryRecentLocationStore()),
        storagePermissionRepositoryProvider.overrideWithValue(
          const FakeStoragePermissionRepository(),
        ),
        searchIndexStoreProvider.overrideWithValue(indexStore),
        fileSearchControllerProvider.overrideWith(
          (ref) => FileSearchController(
            const _MultiVolumeStorageRepository(),
            indexStore: indexStore,
            mediaStore: null,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(searchIndexPreWarmProvider);
    await _waitForIndex(indexStore, _MultiVolumeStorageRepository.root);

    expect(
        await indexStore.hasIndex(_MultiVolumeStorageRepository.root), isTrue);
  });

  test('does not prewarm without browse permission', () async {
    final indexStore = InMemorySearchIndexStore();
    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWithValue(
          const _MultiVolumeStorageRepository(),
        ),
        recentLocationStoreProvider
            .overrideWithValue(InMemoryRecentLocationStore()),
        storagePermissionRepositoryProvider.overrideWithValue(
          const FakeStoragePermissionRepository(
            initialState: StoragePermissionState.needsFullAccess(),
            requestState: StoragePermissionState.needsFullAccess(),
          ),
        ),
        searchIndexStoreProvider.overrideWithValue(indexStore),
        fileSearchControllerProvider.overrideWith(
          (ref) => FileSearchController(
            const _MultiVolumeStorageRepository(),
            indexStore: indexStore,
            mediaStore: null,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(searchIndexPreWarmProvider);
    // Give the explorer's permission check time to settle so the listener is
    // exercised with a non-browsable state.
    await _pumpEventQueue();

    expect(
        await indexStore.hasIndex(_MultiVolumeStorageRepository.root), isFalse);
  });
}

Future<void> _waitForIndex(
  InMemorySearchIndexStore indexStore,
  String rootPath,
) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (await indexStore.hasIndex(rootPath)) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Index was not prewarmed for $rootPath');
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

class _MultiVolumeStorageRepository implements StorageRepository {
  const _MultiVolumeStorageRepository();

  static const root = '/storage/emulated/0';

  @override
  Future<List<StorageVolume>> getStorageVolumes() async {
    return [
      const StorageVolume(
        id: 'primary',
        label: 'Internal storage',
        path: root,
        summary: StorageSummary(label: 'Internal', usedBytes: 1, totalBytes: 2),
        isPrimary: true,
      ),
    ];
  }

  @override
  Future<StorageSummary> getPrimaryStorageSummary() async {
    return const StorageSummary(label: 'Internal', usedBytes: 1, totalBytes: 2);
  }

  @override
  Future<DirectoryListing> listDirectory(String path) async {
    return DirectoryListing(
      path: path,
      entries: [
        FileSystemEntry(
          name: 'docs',
          path: '/storage/emulated/0/docs',
          type: FileSystemEntryType.folder,
          modifiedAt: DateTime(2026),
          childrenCount: 1,
        ),
      ],
    );
  }

  @override
  Future<Map<FileSystemEntryType, int>> countEntriesByType(
      String rootPath) async {
    return const {};
  }

  @override
  Future<bool> createFolder(String path) async => true;

  @override
  Future<bool> createFile(String path, {String content = ''}) async => true;
}
