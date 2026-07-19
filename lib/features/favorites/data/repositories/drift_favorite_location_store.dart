import 'package:drift/drift.dart';
import 'package:file_explorer/features/favorites/domain/entities/favorite_location.dart';
import 'package:file_explorer/features/favorites/domain/repositories/favorite_location_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftFavoriteLocationStore implements FavoriteLocationStore {
  const DriftFavoriteLocationStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<FavoriteLocation>> loadFavorites() async {
    final rows = await (_database.select(_database.favoriteLocationRows)
          ..orderBy([
            (table) => OrderingTerm.desc(table.updatedAt),
          ]))
        .get();
    return rows.map(_toFavorite).toList();
  }

  @override
  Future<void> saveFavorite(FavoriteLocation favorite) {
    return _database
        .into(_database.favoriteLocationRows)
        .insertOnConflictUpdate(_toCompanion(favorite));
  }

  @override
  Future<void> deleteFavorite(String path) {
    return (_database.delete(_database.favoriteLocationRows)
          ..where((table) => table.path.equals(path)))
        .go();
  }

  FavoriteLocation _toFavorite(FavoriteLocationRow row) {
    return FavoriteLocation(
      path: row.path,
      label: row.label,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  FavoriteLocationRowsCompanion _toCompanion(FavoriteLocation favorite) {
    return FavoriteLocationRowsCompanion.insert(
      path: favorite.path,
      label: favorite.label,
      createdAt: favorite.createdAt,
      updatedAt: favorite.updatedAt,
    );
  }
}
