import 'dart:async';

import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/recents/presentation/controllers/recents_controller.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;

final explorerControllerProvider =
    StateNotifierProvider<ExplorerController, ExplorerState>((ref) {
  return ExplorerController(ref)..loadInitialDirectory();
});

/// Folder Explorer opens on launch, loaded from persisted settings before the
/// app starts. `null` uses the primary storage root.
final explorerStartPathProvider = Provider<String?>((ref) => null);

const Object _unsetSelectionAnchor = Object();

class ExplorerState {
  const ExplorerState({
    this.currentPath = FakeStorageRepository.rootPath,
    this.volumes = const AsyncValue.loading(),
    this.listing = const AsyncValue.loading(),
    this.permission = const AsyncValue.data(StoragePermissionState.checking()),
    this.summary = const AsyncValue.loading(),
    this.selectedPaths = const [],
    this.isSelectionMode = false,
    this.selectionAnchorPath,
  });

  final String currentPath;
  final AsyncValue<List<StorageVolume>> volumes;
  final AsyncValue<DirectoryListing> listing;
  final AsyncValue<StoragePermissionState> permission;
  final AsyncValue<StorageSummary> summary;
  final List<String> selectedPaths;
  final bool isSelectionMode;

  /// Path that started the current selection. Range selection extends from
  /// this anchor to the tapped entry.
  final String? selectionAnchorPath;

  ExplorerState copyWith({
    String? currentPath,
    AsyncValue<List<StorageVolume>>? volumes,
    AsyncValue<DirectoryListing>? listing,
    AsyncValue<StoragePermissionState>? permission,
    AsyncValue<StorageSummary>? summary,
    List<String>? selectedPaths,
    bool? isSelectionMode,
    Object? selectionAnchorPath = _unsetSelectionAnchor,
  }) {
    return ExplorerState(
      currentPath: currentPath ?? this.currentPath,
      volumes: volumes ?? this.volumes,
      listing: listing ?? this.listing,
      permission: permission ?? this.permission,
      summary: summary ?? this.summary,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectionAnchorPath: identical(
        selectionAnchorPath,
        _unsetSelectionAnchor,
      )
          ? this.selectionAnchorPath
          : selectionAnchorPath as String?,
    );
  }
}

class ExplorerController extends StateNotifier<ExplorerState> {
  ExplorerController(this._ref) : super(const ExplorerState());

  final Ref _ref;

  Future<void> loadInitialDirectory({
    bool requestAccessOnLaunch = false,
  }) async {
    final permissionRepository = _ref.read(storagePermissionRepositoryProvider);
    state = state.copyWith(permission: const AsyncValue.loading());

    final permission = await AsyncValue.guard(
      permissionRepository.checkPermission,
    );
    state = state.copyWith(permission: permission);

    final permissionValue = permission.value;
    if (permissionValue == null || !permissionValue.canBrowse) {
      if (requestAccessOnLaunch &&
          permissionValue != null &&
          permissionValue.canRequestFullAccess) {
        await requestFullStorageAccess();
        return;
      }
      _showBlockedStorageState();
      return;
    }

    final repository = _ref.read(storageRepositoryProvider);
    state = state.copyWith(
      volumes: const AsyncValue.loading(),
      listing: const AsyncValue.loading(),
      summary: const AsyncValue.loading(),
    );

    final volumes = await AsyncValue.guard(repository.getStorageVolumes);
    final volumeList = volumes.value ?? const <StorageVolume>[];
    final primaryVolume = _primaryVolumeFrom(volumeList);
    final rootPath = primaryVolume?.path ?? FakeStorageRepository.rootPath;
    final homePath = _ref.read(explorerStartPathProvider);
    final startPath =
        homePath == null || homePath.isEmpty ? rootPath : homePath;
    final summary = await AsyncValue.guard(
      () => _summaryForVolume(primaryVolume, repository),
    );

    state = state.copyWith(
      currentPath: startPath,
      volumes: volumes,
      summary: summary,
      listing: const AsyncValue.loading(),
    );

    await openDirectory(startPath);
    if (startPath != rootPath && state.listing.hasError) {
      await openDirectory(rootPath);
    }
  }

  Future<void> requestFullStorageAccess() async {
    final permissionRepository = _ref.read(storagePermissionRepositoryProvider);
    state = state.copyWith(permission: const AsyncValue.loading());

    final permission = await AsyncValue.guard(
      permissionRepository.requestFullAccess,
    );
    state = state.copyWith(permission: permission);

    final permissionValue = permission.value;
    if (permissionValue != null && permissionValue.canBrowse) {
      await loadInitialDirectory();
    } else {
      _showBlockedStorageState();
    }
  }

  void _showBlockedStorageState() {
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
  }

  Future<void> openDirectory(String path, {bool recordRecent = true}) async {
    final repository = _ref.read(storageRepositoryProvider);
    state = state.copyWith(
      currentPath: path,
      listing: const AsyncValue.loading(),
      selectedPaths: const [],
      isSelectionMode: false,
      selectionAnchorPath: null,
    );

    final listing =
        await AsyncValue.guard(() => repository.listDirectory(path));
    state = state.copyWith(listing: listing);
    if (listing.hasValue && recordRecent) {
      _recordRecent(path: path);
    }
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
    if (listing.hasValue) {
      _recordRecent(path: volume.path, label: volume.label);
    }
  }

  Future<void> openParentDirectory() async {
    final currentPath = state.currentPath;
    final volumeRoot = _volumeForCurrentPath()?.path;

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

  void toggleSelection(String path) {
    final currentSelected = state.selectedPaths;
    if (currentSelected.contains(path)) {
      final remaining = currentSelected.where((p) => p != path).toList();
      state = state.copyWith(
        selectedPaths: remaining,
        isSelectionMode: remaining.isNotEmpty,
        selectionAnchorPath: state.selectionAnchorPath == path
            ? (remaining.isEmpty ? null : remaining.last)
            : state.selectionAnchorPath,
      );
    } else {
      state = state.copyWith(
        selectedPaths: [...currentSelected, path],
        isSelectionMode: true,
        selectionAnchorPath: path,
      );
    }
  }

  void selectAll(List<String> paths) {
    state = state.copyWith(
      selectedPaths: paths,
      isSelectionMode: paths.isNotEmpty,
      selectionAnchorPath: paths.isEmpty ? null : paths.first,
    );
  }

  /// Selects every entry between the current anchor and [path] in
  /// [orderedPaths], matching shift-click behavior in desktop file managers.
  void selectTo(String path, {required List<String> orderedPaths}) {
    final anchor = state.selectionAnchorPath;
    if (anchor == null) {
      toggleSelection(path);
      return;
    }

    final anchorIndex = orderedPaths.indexOf(anchor);
    final targetIndex = orderedPaths.indexOf(path);
    if (anchorIndex == -1 || targetIndex == -1) {
      toggleSelection(path);
      return;
    }

    final start = anchorIndex < targetIndex ? anchorIndex : targetIndex;
    final end = anchorIndex < targetIndex ? targetIndex : anchorIndex;
    state = state.copyWith(
      selectedPaths: orderedPaths.sublist(start, end + 1),
      isSelectionMode: true,
      selectionAnchorPath: anchor,
    );
  }

  /// Extends the current selection from the anchor to the first entry.
  void selectToFirst({required List<String> orderedPaths}) {
    _selectToBoundary(orderedPaths, fromStart: true);
  }

  /// Extends the current selection from the anchor to the last entry.
  void selectToLast({required List<String> orderedPaths}) {
    _selectToBoundary(orderedPaths, fromStart: false);
  }

  void _selectToBoundary(
    List<String> orderedPaths, {
    required bool fromStart,
  }) {
    if (orderedPaths.isEmpty) return;

    final anchorIndex = state.selectionAnchorPath == null
        ? -1
        : orderedPaths.indexOf(state.selectionAnchorPath!);
    if (anchorIndex == -1) {
      final boundary = fromStart ? orderedPaths.first : orderedPaths.last;
      state = state.copyWith(
        selectedPaths: [boundary],
        isSelectionMode: true,
        selectionAnchorPath: boundary,
      );
      return;
    }

    final boundaryIndex = fromStart ? 0 : orderedPaths.length - 1;
    final range = fromStart
        ? orderedPaths.sublist(0, anchorIndex + 1)
        : orderedPaths.sublist(anchorIndex, boundaryIndex + 1);
    final selectedSet = {...state.selectedPaths, ...range};
    final selected = [
      for (final path in orderedPaths)
        if (selectedSet.contains(path)) path,
    ];
    state = state.copyWith(
      selectedPaths: selected,
      isSelectionMode: true,
      selectionAnchorPath: state.selectionAnchorPath,
    );
  }

  void selectInterval({List<String>? paths}) {
    if (state.selectedPaths.length < 2) return;
    final allPaths =
        paths ?? state.listing.value?.entries.map((e) => e.path).toList();
    if (allPaths == null || allPaths.isEmpty) return;

    final indices = state.selectedPaths
        .map((path) => allPaths.indexOf(path))
        .where((index) => index != -1)
        .toList();

    if (indices.length < 2) return;

    final minIndex = indices.reduce((a, b) => a < b ? a : b);
    final maxIndex = indices.reduce((a, b) => a > b ? a : b);
    final selected = allPaths.sublist(minIndex, maxIndex + 1);

    state = state.copyWith(
      selectedPaths: selected,
      isSelectionMode: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedPaths: const [],
      isSelectionMode: false,
      selectionAnchorPath: null,
    );
  }

  void exitSelectionMode() {
    state = state.copyWith(
      selectedPaths: const [],
      isSelectionMode: false,
      selectionAnchorPath: null,
    );
  }

  Future<bool> createFolder(String name) async {
    final repository = _ref.read(storageRepositoryProvider);
    final path = p.join(state.currentPath, name);
    final success = await repository.createFolder(path);
    if (success) {
      await refresh();
    }
    return success;
  }

  Future<bool> createFile(String name, {String content = ''}) async {
    final repository = _ref.read(storageRepositoryProvider);
    final path = p.join(state.currentPath, name);
    final success = await repository.createFile(path, content: content);
    if (success) {
      await refresh();
    }
    return success;
  }

  StorageVolume? _volumeForCurrentPath() {
    final listingVolume = state.listing.value?.volume;
    if (listingVolume != null) {
      return listingVolume;
    }

    final volumes = state.volumes.value ?? const <StorageVolume>[];
    for (final volume in volumes) {
      if (state.currentPath.startsWith(volume.path)) {
        return volume;
      }
    }
    return volumes.isEmpty ? null : volumes.first;
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

  void _recordRecent({
    required String path,
    String? label,
  }) {
    unawaited(
      _ref.read(recentsControllerProvider.notifier).recordLocation(
            path: path,
            label: label ?? _labelForPath(path),
          ),
    );
  }

  String _labelForPath(String path) {
    final name = p.basename(path);
    if (name.isNotEmpty && name != '.') {
      return name;
    }
    return path;
  }
}
