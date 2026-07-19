import 'dart:async';

import 'package:file_explorer/features/recents/data/repositories/recent_location_store_provider.dart';
import 'package:file_explorer/features/recents/domain/entities/recent_location.dart';
import 'package:file_explorer/features/recents/domain/repositories/recent_location_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recentsControllerProvider =
    StateNotifierProvider<RecentsController, RecentsState>((ref) {
  final controller = RecentsController(
    ref.read(recentLocationStoreProvider),
  );
  unawaited(controller.loadRecents());
  return controller;
});

class RecentsState {
  const RecentsState({
    this.locations = const [],
    this.isLoading = false,
  });

  final List<RecentLocation> locations;
  final bool isLoading;

  RecentsState copyWith({
    List<RecentLocation>? locations,
    bool? isLoading,
  }) {
    return RecentsState(
      locations: locations ?? this.locations,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RecentsController extends StateNotifier<RecentsState> {
  RecentsController(this._store) : super(const RecentsState());

  final RecentLocationStore _store;

  Future<void> loadRecents() async {
    state = state.copyWith(isLoading: true);
    final recents = await _store.loadRecents();
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      locations: recents,
      isLoading: false,
    );
  }

  Future<void> recordLocation({
    required String path,
    required String label,
    bool isFolder = true,
  }) async {
    final now = DateTime.now();
    final existing = _recentFor(path);
    final recent = existing == null
        ? RecentLocation(
            path: path,
            label: label,
            openedAt: now,
            isFolder: isFolder,
          )
        : existing.copyWith(
            label: label,
            openedAt: now,
            openCount: existing.openCount + 1,
            isFolder: isFolder,
          );

    await _store.saveRecent(recent);
    if (!mounted) {
      return;
    }
    state = state.copyWith(locations: _upsertRecent(recent));
  }

  Future<void> removeRecent(String path) async {
    await _store.deleteRecent(path);
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      locations: [
        for (final recent in state.locations)
          if (recent.path != path) recent,
      ],
    );
  }

  Future<void> clearRecents() async {
    await _store.clearRecents();
    if (!mounted) {
      return;
    }
    state = state.copyWith(locations: const []);
  }

  RecentLocation? _recentFor(String path) {
    for (final recent in state.locations) {
      if (recent.path == path) {
        return recent;
      }
    }
    return null;
  }

  List<RecentLocation> _upsertRecent(RecentLocation recent) {
    final recents = [
      recent,
      for (final existing in state.locations)
        if (existing.path != recent.path) existing,
    ];
    recents.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return recents;
  }
}
