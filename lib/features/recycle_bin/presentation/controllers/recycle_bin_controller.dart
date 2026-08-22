import 'package:file_explorer/features/recycle_bin/data/recycle_bin_repository.dart';
import 'package:file_explorer/features/recycle_bin/domain/entities/trash_item.dart';
import 'package:flutter_riverpod/legacy.dart';

final recycleBinControllerProvider =
    StateNotifierProvider<RecycleBinController, RecycleBinState>((ref) {
  return RecycleBinController(const RecycleBinRepository());
});

final recycleBinGridViewProvider = StateProvider<bool>((ref) => false);

class RecycleBinState {
  const RecycleBinState({
    this.loading = false,
    this.items = const [],
    this.error,
  });

  final bool loading;
  final List<TrashItem> items;
  final String? error;
}

class RecycleBinController extends StateNotifier<RecycleBinState> {
  RecycleBinController(this._repository) : super(const RecycleBinState());

  final RecycleBinRepository _repository;
  String? _volumeRoot;

  Future<void> load(String volumeRoot) async {
    _volumeRoot = volumeRoot;
    await refresh();
  }

  Future<void> refresh() async {
    final volumeRoot = _volumeRoot;
    if (volumeRoot == null) return;

    state = const RecycleBinState(loading: true);
    try {
      final items =
          await _repository.listTrash(RecycleBinRepository.trashRootFor(volumeRoot));
      state = RecycleBinState(loading: false, items: items);
    } catch (error) {
      state = RecycleBinState(loading: false, error: error.toString());
    }
  }

  Future<void> restore(TrashItem item) async {
    await restoreMany([item]);
  }

  Future<void> restoreMany(List<TrashItem> items) async {
    for (final item in items) {
      try {
        await _repository.restore(item);
      } catch (_) {
        // Best-effort; refresh shows the current state regardless.
      }
    }
    await refresh();
  }

  Future<void> deletePermanently(TrashItem item) async {
    await deleteMany([item]);
  }

  Future<void> deleteMany(List<TrashItem> items) async {
    for (final item in items) {
      try {
        await _repository.deletePermanently(item);
      } catch (_) {}
    }
    await refresh();
  }

  Future<void> emptyTrash() async {
    final volumeRoot = _volumeRoot;
    if (volumeRoot == null) return;
    try {
      await _repository.emptyTrash(RecycleBinRepository.trashRootFor(volumeRoot));
    } catch (_) {}
    await refresh();
  }
}
