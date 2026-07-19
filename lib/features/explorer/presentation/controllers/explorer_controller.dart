import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final explorerControllerProvider =
    StateNotifierProvider<ExplorerController, ExplorerState>((ref) {
  return ExplorerController(ref)..loadInitialDirectory();
});

class ExplorerState {
  const ExplorerState({
    this.currentPath = FakeStorageRepository.rootPath,
    this.volumes = const AsyncValue.loading(),
    this.listing = const AsyncValue.loading(),
    this.permission = const AsyncValue.data(StoragePermissionState.checking()),
    this.summary = const AsyncValue.loading(),
  });

  final String currentPath;
  final AsyncValue<List<StorageVolume>> volumes;
  final AsyncValue<DirectoryListing> listing;
  final AsyncValue<StoragePermissionState> permission;
  final AsyncValue<StorageSummary> summary;

  ExplorerState copyWith({
    String? currentPath,
    AsyncValue<List<StorageVolume>>? volumes,
    AsyncValue<DirectoryListing>? listing,
    AsyncValue<StoragePermissionState>? permission,
    AsyncValue<StorageSummary>? summary,
  }) {
    return ExplorerState(
      currentPath: currentPath ?? this.currentPath,
      volumes: volumes ?? this.volumes,
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
        volumes: const AsyncValue.data([]),
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
      volumes: const AsyncValue.loading(),
      listing: const AsyncValue.loading(),
      summary: const AsyncValue.loading(),
    );

    final volumes = await AsyncValue.guard(repository.getStorageVolumes);
    final volumeList = volumes.valueOrNull ?? const <StorageVolume>[];
    final primaryVolume = _primaryVolumeFrom(volumeList);
    final rootPath = primaryVolume?.path ?? FakeStorageRepository.rootPath;
    final summary = await AsyncValue.guard(
      () => _summaryForVolume(primaryVolume, repository),
    );

    state = state.copyWith(
      currentPath: rootPath,
      volumes: volumes,
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

  Future<void> openStorageVolume(StorageVolume volume) async {
    final repository = _ref.read(storageRepositoryProvider);
    state = state.copyWith(
      currentPath: volume.path,
      summary: const AsyncValue.loading(),
      listing: const AsyncValue.loading(),
    );

    final summary = await AsyncValue.guard(
      () => _summaryForVolume(volume, repository),
    );
    final listing =
        await AsyncValue.guard(() => repository.listDirectory(volume.path));

    state = state.copyWith(
      summary: summary,
      listing: listing,
    );
  }

  Future<void> openParentDirectory() async {
    final currentPath = state.currentPath;
    final volumeRoot = state.listing.valueOrNull?.volume?.path;

    if (volumeRoot != null && currentPath == volumeRoot) {
      return;
    }
    if (currentPath == p.dirname(currentPath)) {
      return;
    }

    await openDirectory(p.dirname(currentPath));
  }

  Future<void> refresh() {
    return openDirectory(state.currentPath);
  }

  StorageVolume? _primaryVolumeFrom(List<StorageVolume> volumes) {
    for (final volume in volumes) {
      if (volume.isPrimary) {
        return volume;
      }
    }
    return volumes.isEmpty ? null : volumes.first;
  }

  Future<StorageSummary> _summaryForVolume(
    StorageVolume? volume,
    StorageRepository repository,
  ) async {
    final summary = volume?.summary;
    if (summary != null) {
      return summary;
    }
    return repository.getPrimaryStorageSummary();
  }
}
