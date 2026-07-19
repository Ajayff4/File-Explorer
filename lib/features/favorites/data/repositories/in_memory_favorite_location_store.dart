import 'package:file_explorer/features/favorites/domain/entities/favorite_location.dart';
import 'package:file_explorer/features/favorites/domain/repositories/favorite_location_store.dart';

class InMemoryFavoriteLocationStore implements FavoriteLocationStore {
  final Map<String, FavoriteLocation> _favorites = {};

  @override
  Future<List<FavoriteLocation>> loadFavorites() async {
    final favorites = _favorites.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return favorites;
  }

  @override
  Future<void> saveFavorite(FavoriteLocation favorite) async {
    _favorites[favorite.path] = favorite;
  }

  @override
  Future<void> deleteFavorite(String path) async {
    _favorites.remove(path);
  }
}
