import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/recents/data/repositories/in_memory_recent_location_store.dart';
import 'package:file_explorer/features/recents/data/repositories/recent_location_store_provider.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/fake_storage_permission_repository.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:file_explorer/features/storage_permissions/domain/repositories/storage_permission_repository.dart';
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
    expect(initialState.volumes.value, hasLength(2));
    expect(initialState.currentPath, _MultiVolumeStorageRepository.primaryPath);

    await container
        .read(explorerControllerProvider.notifier)
        .openStorageVolume(repository.removableVolume);

    final selectedState = container.read(explorerControllerProvider);
    expect(selectedState.currentPath, _MultiVolumeStorageRepository.sdCardPath);
    expect(selectedState.summary.value?.label, 'SD card');
    expect(selectedState.listing.value?.volume?.label, 'SD card');

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

    const subfolderPath =
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

  test('requests full access when prompted on launch', () async {
    final repository = _MultiVolumeStorageRepository();
    final permissionRepository = _RecordingStoragePermissionRepository(
      initialState: const StoragePermissionState.needsFullAccess(),
      grantedState: const StoragePermissionState.fullAccess(
        accessMode: StorageAccessMode.allFiles,
        message: 'Full storage access is enabled',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWithValue(repository),
        recentLocationStoreProvider.overrideWithValue(
          InMemoryRecentLocationStore(),
        ),
        storagePermissionRepositoryProvider
            .overrideWithValue(permissionRepository),
        explorerControllerProvider.overrideWith(
          (ref) => ExplorerController(ref)
            ..loadInitialDirectory(requestAccessOnLaunch: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForExplorerLoad(container);

    final state = container.read(explorerControllerProvider);
    expect(permissionRepository.requestCount, 1);
    expect(state.permission.value?.canBrowse, isTrue);
    expect(state.volumes.value, hasLength(2));
  });

  test('does not request full access on a regular load', () async {
    final permissionRepository = _RecordingStoragePermissionRepository(
      initialState: const StoragePermissionState.needsFullAccess(),
      grantedState: const StoragePermissionState.fullAccess(
        accessMode: StorageAccessMode.allFiles,
        message: 'Full storage access is enabled',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWithValue(
          _MultiVolumeStorageRepository(),
        ),
        recentLocationStoreProvider.overrideWithValue(
          InMemoryRecentLocationStore(),
        ),
        storagePermissionRepositoryProvider
            .overrideWithValue(permissionRepository),
      ],
    );
    addTearDown(container.dispose);

    await _waitForExplorerLoad(container);

    expect(permissionRepository.requestCount, 0);
    expect(
      container.read(explorerControllerProvider).permission.value?.canBrowse,
      isFalse,
    );
  });

  test('opens the configured home folder on launch', () async {
    final container = _createExplorerContainer(
      startPath: '${_MultiVolumeStorageRepository.primaryPath}/Documents',
    );
    addTearDown(container.dispose);

    await _waitForExplorerLoad(container);

    final state = container.read(explorerControllerProvider);
    expect(
      state.currentPath,
      '${_MultiVolumeStorageRepository.primaryPath}/Documents',
    );
    expect(state.listing.hasValue, isTrue);
  });

  test('falls back to the primary root when the home folder fails', () async {
    final container = _createExplorerContainer(
      startPath: '/missing/home-folder',
    );
    addTearDown(container.dispose);

    await _waitForExplorerLoad(container);

    final state = container.read(explorerControllerProvider);
    expect(
      state.currentPath,
      _MultiVolumeStorageRepository.primaryPath,
    );
    expect(state.listing.hasValue, isTrue);
  });

  group('range selection', () {
    const a = '/storage/emulated/0/a';
    const b = '/storage/emulated/0/b';
    const c = '/storage/emulated/0/c';
    const d = '/storage/emulated/0/d';
    const orderedPaths = [a, b, c, d];

    late ProviderContainer container;
    late ExplorerController controller;

    setUp(() async {
      container = _createExplorerContainer();
      addTearDown(container.dispose);
      await _waitForExplorerLoad(container);
      controller = container.read(explorerControllerProvider.notifier);
    });

    ExplorerState readState() => container.read(explorerControllerProvider);

    test('toggleSelection sets and clears the anchor', () {
      controller.toggleSelection(b);

      var state = readState();
      expect(state.selectedPaths, [b]);
      expect(state.isSelectionMode, isTrue);
      expect(state.selectionAnchorPath, b);

      controller.toggleSelection(b);

      state = readState();
      expect(state.selectedPaths, isEmpty);
      expect(state.isSelectionMode, isFalse);
      expect(state.selectionAnchorPath, isNull);
    });

    test('toggleSelection keeps the anchor when another entry is toggled off',
        () {
      controller.toggleSelection(b);
      controller.toggleSelection(d);

      expect(readState().selectionAnchorPath, d);

      controller.toggleSelection(b);

      final state = readState();
      expect(state.selectedPaths, [d]);
      expect(state.selectionAnchorPath, d);
    });

    test('selectTo extends the selection in both directions', () {
      controller.toggleSelection(b);

      controller.selectTo(d, orderedPaths: orderedPaths);
      expect(readState().selectedPaths, [b, c, d]);

      controller.selectTo(a, orderedPaths: orderedPaths);
      final state = readState();
      expect(state.selectedPaths, [a, b]);
      expect(state.selectionAnchorPath, b);
    });

    test('selectTo falls back to a toggle without an anchor', () {
      controller.selectTo(c, orderedPaths: orderedPaths);

      final state = readState();
      expect(state.selectedPaths, [c]);
      expect(state.isSelectionMode, isTrue);
      expect(state.selectionAnchorPath, c);
    });

    test('selectToFirst and selectToLast union ranges around the anchor', () {
      controller.toggleSelection(c);

      controller.selectToFirst(orderedPaths: orderedPaths);
      expect(readState().selectedPaths, [a, b, c]);

      controller.selectToLast(orderedPaths: orderedPaths);
      final state = readState();
      expect(state.selectedPaths, [a, b, c, d]);
      expect(state.selectionAnchorPath, c);
    });

    test('selectAll and exitSelectionMode maintain the anchor', () {
      controller.selectAll(orderedPaths);
      expect(readState().selectedPaths, orderedPaths);
      expect(readState().selectionAnchorPath, a);

      controller.exitSelectionMode();
      final state = readState();
      expect(state.selectedPaths, isEmpty);
      expect(state.selectionAnchorPath, isNull);
    });
  });
}

class _RecordingStoragePermissionRepository
    implements StoragePermissionRepository {
  _RecordingStoragePermissionRepository({
    required this.initialState,
    required this.grantedState,
  }) : _current = initialState;

  final StoragePermissionState initialState;
  final StoragePermissionState grantedState;
  StoragePermissionState _current;
  int requestCount = 0;

  @override
  Future<StoragePermissionState> checkPermission() async {
    return _current;
  }

  @override
  Future<StoragePermissionState> requestFullAccess() async {
    requestCount += 1;
    _current = grantedState;
    return _current;
  }
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

ProviderContainer _createExplorerContainer({String? startPath}) {
  return ProviderContainer(
    overrides: [
      storageRepositoryProvider.overrideWithValue(
        _MultiVolumeStorageRepository(),
      ),
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
      explorerStartPathProvider.overrideWithValue(startPath),
    ],
  );
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
  Future<Map<FileSystemEntryType, int>> countEntriesByType(
      String rootPath) async {
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

  @override
  Future<bool> createFolder(String path) async {
    return true;
  }

  @override
  Future<bool> createFile(String path, {String content = ''}) async {
    return true;
  }
}
