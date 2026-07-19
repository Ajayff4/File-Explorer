import 'package:file_explorer/features/favorites/data/repositories/favorite_location_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/favorites/data/repositories/favorite_location_store_io.dart';
import 'package:file_explorer/features/favorites/domain/repositories/favorite_location_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoriteLocationStoreProvider = Provider<FavoriteLocationStore>((ref) {
  return createFavoriteLocationStore(ref);
});
