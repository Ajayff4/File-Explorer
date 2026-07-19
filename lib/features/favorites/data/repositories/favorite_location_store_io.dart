import 'package:file_explorer/features/favorites/data/repositories/drift_favorite_location_store.dart';
import 'package:file_explorer/features/favorites/domain/repositories/favorite_location_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

FavoriteLocationStore createFavoriteLocationStore(Ref ref) {
  return DriftFavoriteLocationStore(ref.watch(appDatabaseProvider));
}
