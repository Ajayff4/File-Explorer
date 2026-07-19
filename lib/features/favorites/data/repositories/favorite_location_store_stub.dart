import 'package:file_explorer/features/favorites/data/repositories/in_memory_favorite_location_store.dart';
import 'package:file_explorer/features/favorites/domain/repositories/favorite_location_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

FavoriteLocationStore createFavoriteLocationStore(Ref ref) {
  return InMemoryFavoriteLocationStore();
}
