import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/recents/data/repositories/in_memory_recent_location_store.dart';
import 'package:file_explorer/features/recents/data/repositories/recent_location_store_provider.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/fake_storage_permission_repository.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opens a selected storage volume root', () async {
    final repository = _MultiVolumeStorageRepository();
    final recentStore = InMemoryRecentLocationStore();
    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWithValue(repository),
        recentLocationStoreProvider.overrideWithValue(recentStore),
        storagePermissionRepositoryProvider.overrideWithValue(
          const FakeStoragePermissionRepository(
            initialState: StoragePermissionState.fullAccess(
              accessMode: StorageAccessMode.allFiles,
              message: 'Full storage access is enabled',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForExplorerLoad(container);

    final initialState = container.read(explorerControllerProvider);
    expect(initialState.volumes.valueOrNull, hasLength(2));
    expect(initialState.currentPath, _MultiVolumeStorageRepository.primaryPath);

    await container
        .read(explorerControllerProvider.notifier)
        .openStorageVolume(repository.removableVolume);

    final selectedState = container.read(explorerControllerProvider);
    expect(selectedState.currentPath, _MultiVolumeStorageRepository.sdCardPath);
    expect(selectedState.summary.valueOrNull?.label, 'SD card');
    expect(selectedState.listing.valueOrNull?.volume?.label, 'SD card');

    final recentPaths = (await recentStore.loadRecents()).map(
      (recent) => recent.path,
    );
    expect(recentPaths, contains(_MultiVolumeStorageRepository.sdCardPath));
  });

  test('openParentDirectory navigates up while listing is loading', () async {
    final repository = _MultiVolumeStorageRepository();
    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWithValue(repository),
        recentLocationStoreProvider.overrideWithValue(
          InMemoryRecentLocationStore(),
        ),
        storagePermissionRepositoryProvider.overrideWithValue(
          const FakeStoragePermissionRepository(
            initialState: StoragePermissionState.fullAccess(
              accessMode: StorageAccessMode.allFiles,
              message: 'Full storage access is enabled',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForExplorerLoad(container);

    final subfolderPath =
        '${_MultiVolumeStorageRepository.primaryPath}/Documents/Notes';
    container.read(explorerControllerProvider.notifier).state =
        container.read(explorerControllerProvider).copyWith(
              currentPath: subfolderPath,
              listing: const AsyncValue.loading(),
            );

    await container
        .read(explorerControllerProvider.notifier)
        .openParentDirectory();

    expect(
      container.read(explorerControllerProvider).currentPath,
      '${_MultiVolumeStorageRepository.primaryPath}/Documents',
    );
  });

  test('openParentDirectory stops at volume root', () async {
    final repository = _MultiVolumeStorageRepository();
    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWithValue(repository),
        recentLocationStoreProvider.overrideWithValue(
          InMemoryRecentLocationStore(),
        ),
        storagePermissionRepositoryProvider.overrideWithValue(
          const FakeStoragePermissionRepository(
            initialState: StoragePermissionState.fullAccess(
              accessMode: StorageAccessMode.allFiles,
              message: 'Full storage access is enabled',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForExplorerLoad(container);

    await container
        .read(explorerControllerProvider.notifier)
        .openParentDirectory();

    expect(
      container.read(explorerControllerProvider).currentPath,
      _MultiVolumeStorageRepository.primaryPath,
    );
  });
}

Future<void> _waitForExplorerLoad(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    final state = container.read(explorerControllerProvider);
    if (state.listing.hasValue && state.volumes.hasValue) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Explorer did not finish loading');
}

class _MultiVolumeStorageRepository implements StorageRepository {
  static const primaryPath = '/storage/emulated/0';
  static const sdCardPath = '/storage/0000-1111';

  final removableVolume = const StorageVolume(
    id: 'sd-card',
    label: 'SD card',
    path: sdCardPath,
    summary: StorageSummary(
      label: 'SD card',
      usedBytes: 40,
      totalBytes: 100,
    ),
  );

  @override
  Future<List<StorageVolume>> getStorageVolumes() async {
    return [
      const StorageVolume(
        id: 'primary',
        label: 'Internal storage',
        path: primaryPath,
        summary: StorageSummary(
          label: 'Internal storage',
          usedBytes: 80,
          totalBytes: 100,
        ),
        isPrimary: true,
      ),
      removableVolume,
    ];
  }

  @override
  Future<StorageSummary> getPrimaryStorageSummary() async {
    return const StorageSummary(
      label: 'Internal storage',
      usedBytes: 80,
      totalBytes: 100,
    );
  }

  @override
  Future<DirectoryListing> listDirectory(String path) async {
    final volumes = await getStorageVolumes();
    final volume = volumes.firstWhere((volume) => path.startsWith(volume.path));
    return DirectoryListing(
      path: path,
      volume: volume,
      entries: [
        FileSystemEntry(
          name: 'Documents',
          path: '$path/Documents',
          type: FileSystemEntryType.folder,
          modifiedAt: DateTime(2026),
          childrenCount: 1,
        ),
      ],
    );
  }

  @override
  Future<Map<FileSystemEntryType, int>> countEntriesByType(String rootPath) async {
    return {
      FileSystemEntryType.folder: 5,
      FileSystemEntryType.image: 10,
      FileSystemEntryType.video: 2,
      FileSystemEntryType.audio: 8,
      FileSystemEntryType.document: 3,
      FileSystemEntryType.archive: 1,
      FileSystemEntryType.app: 0,
      FileSystemEntryType.other: 4,
    };
  }
}
