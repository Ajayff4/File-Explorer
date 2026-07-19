import 'dart:async';

import 'package:file_explorer/features/favorites/data/repositories/favorite_location_store_provider.dart';
import 'package:file_explorer/features/favorites/domain/entities/favorite_location.dart';
import 'package:file_explorer/features/favorites/domain/repositories/favorite_location_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  final controller = FavoritesController(
    ref.read(favoriteLocationStoreProvider),
  );
  unawaited(controller.loadFavorites());
  return controller;
});

class FavoritesState {
  const FavoritesState({
    this.locations = const [],
    this.isLoading = false,
  });

  final List<FavoriteLocation> locations;
  final bool isLoading;

  bool containsPath(String path) {
    return locations.any((favorite) => favorite.path == path);
  }

  FavoritesState copyWith({
    List<FavoriteLocation>? locations,
    bool? isLoading,
  }) {
    return FavoritesState(
      locations: locations ?? this.locations,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._store) : super(const FavoritesState());

  final FavoriteLocationStore _store;

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true);
    final favorites = await _store.loadFavorites();
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      locations: favorites,
      isLoading: false,
    );
  }

  Future<void> toggleFavorite({
    required String path,
    required String label,
  }) {
    if (state.containsPath(path)) {
      return removeFavorite(path);
    }
    return addFavorite(path: path, label: label);
  }

  Future<void> addFavorite({
    required String path,
    required String label,
  }) async {
    final now = DateTime.now();
    final existing = _favoriteFor(path);
    final favorite = existing == null
        ? FavoriteLocation(
            path: path,
            label: label,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(label: label, updatedAt: now);

    await _store.saveFavorite(favorite);
    if (!mounted) {
      return;
    }
    state = state.copyWith(locations: _upsertFavorite(favorite));
  }

  Future<void> removeFavorite(String path) async {
    await _store.deleteFavorite(path);
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      locations: [
        for (final favorite in state.locations)
          if (favorite.path != path) favorite,
      ],
    );
  }

  FavoriteLocation? _favoriteFor(String path) {
    for (final favorite in state.locations) {
      if (favorite.path == path) {
        return favorite;
      }
    }
    return null;
  }

  List<FavoriteLocation> _upsertFavorite(FavoriteLocation favorite) {
    final favorites = [
      favorite,
      for (final existing in state.locations)
        if (existing.path != favorite.path) existing,
    ];
    favorites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return favorites;
  }
}
