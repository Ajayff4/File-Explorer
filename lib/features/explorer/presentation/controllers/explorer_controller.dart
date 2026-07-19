import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final explorerControllerProvider =
    StateNotifierProvider<ExplorerController, ExplorerState>((ref) {
  return ExplorerController(ref)..loadInitialDirectory();
});

class ExplorerState {
  const ExplorerState({
    this.currentPath = FakeStorageRepository.rootPath,
    this.listing = const AsyncValue.loading(),
    this.permission = const AsyncValue.data(StoragePermissionState.checking()),
    this.summary = const AsyncValue.loading(),
  });

  final String currentPath;
  final AsyncValue<DirectoryListing> listing;
  final AsyncValue<StoragePermissionState> permission;
  final AsyncValue<StorageSummary> summary;

  ExplorerState copyWith({
    String? currentPath,
    AsyncValue<DirectoryListing>? listing,
    AsyncValue<StoragePermissionState>? permission,
    AsyncValue<StorageSummary>? summary,
  }) {
    return ExplorerState(
      currentPath: currentPath ?? this.currentPath,
      listing: listing ?? this.listing,
      permission: permission ?? this.permission,
      summary: summary ?? this.summary,
    );
  }
}

class ExplorerController extends StateNotifier<ExplorerState> {
  ExplorerController(this._ref) : super(const ExplorerState());

  final Ref _ref;

  Future<void> loadInitialDirectory() async {
    final permissionRepository = _ref.read(storagePermissionRepositoryProvider);
    state = state.copyWith(permission: const AsyncValue.loading());

    final permission = await AsyncValue.guard(
      permissionRepository.checkPermission,
    );
    state = state.copyWith(permission: permission);

    final permissionValue = permission.valueOrNull;
    if (permissionValue == null || !permissionValue.canBrowse) {
      state = state.copyWith(
        listing: AsyncValue.data(
          DirectoryListing(
            path: state.currentPath,
            entries: const [],
          ),
        ),
        summary: const AsyncValue.data(
          StorageSummary(
            label: 'Storage',
            usedBytes: 0,
            totalBytes: 1,
          ),
        ),
      );
      return;
    }

    final repository = _ref.read(storageRepositoryProvider);
    state = state.copyWith(
      listing: const AsyncValue.loading(),
      summary: const AsyncValue.loading(),
    );

    final volumes = await AsyncValue.guard(repository.getStorageVolumes);
    final summary = await AsyncValue.guard(repository.getPrimaryStorageSummary);
    final volumeList = volumes.valueOrNull ?? const <StorageVolume>[];
    StorageVolume? primaryVolume;
    for (final volume in volumeList) {
      if (volume.isPrimary) {
        primaryVolume = volume;
        break;
      }
    }
    final rootPath = primaryVolume?.path ?? FakeStorageRepository.rootPath;

    state = state.copyWith(
      currentPath: rootPath,
      summary: summary,
      listing: const AsyncValue.loading(),
    );

    await openDirectory(rootPath);
  }

  Future<void> requestFullStorageAccess() async {
    final permissionRepository = _ref.read(storagePermissionRepositoryProvider);
    state = state.copyWith(permission: const AsyncValue.loading());

    final permission = await AsyncValue.guard(
      permissionRepository.requestFullAccess,
    );
    state = state.copyWith(permission: permission);

    final permissionValue = permission.valueOrNull;
    if (permissionValue != null && permissionValue.canBrowse) {
      await loadInitialDirectory();
    }
  }

  Future<void> openDirectory(String path) async {
    final repository = _ref.read(storageRepositoryProvider);
    state = state.copyWith(
      currentPath: path,
      listing: const AsyncValue.loading(),
    );

    final listing =
        await AsyncValue.guard(() => repository.listDirectory(path));
    state = state.copyWith(listing: listing);
  }

  Future<void> refresh() {
    return openDirectory(state.currentPath);
  }
}
