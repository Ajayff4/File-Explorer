import 'package:file_explorer/features/favorites/domain/entities/favorite_location.dart';

abstract interface class FavoriteLocationStore {
  Future<List<FavoriteLocation>> loadFavorites();
  Future<void> saveFavorite(FavoriteLocation favorite);
  Future<void> deleteFavorite(String path);
}
