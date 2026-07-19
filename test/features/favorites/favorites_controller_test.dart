import 'package:file_explorer/features/favorites/data/repositories/in_memory_favorite_location_store.dart';
import 'package:file_explorer/features/favorites/domain/entities/favorite_location.dart';
import 'package:file_explorer/features/favorites/presentation/controllers/favorites_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads saved favorites', () async {
    final store = InMemoryFavoriteLocationStore();
    final now = DateTime(2026);
    await store.saveFavorite(
      FavoriteLocation(
        path: '/storage/emulated/0/Download',
        label: 'Download',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final controller = FavoritesController(store);
    await controller.loadFavorites();

    expect(
        controller.state.locations.single.path, '/storage/emulated/0/Download');
  });

  test('toggles favorite on and off', () async {
    final store = InMemoryFavoriteLocationStore();
    final controller = FavoritesController(store);

    await controller.toggleFavorite(
      path: '/storage/emulated/0/Download',
      label: 'Download',
    );

    expect(
        controller.state.containsPath('/storage/emulated/0/Download'), isTrue);
    expect((await store.loadFavorites()).single.label, 'Download');

    await controller.toggleFavorite(
      path: '/storage/emulated/0/Download',
      label: 'Download',
    );

    expect(controller.state.locations, isEmpty);
    expect(await store.loadFavorites(), isEmpty);
  });

  test('newer favorites sort first', () async {
    final store = InMemoryFavoriteLocationStore();
    final controller = FavoritesController(store);

    await controller.addFavorite(path: '/one', label: 'One');
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await controller.addFavorite(path: '/two', label: 'Two');

    expect(controller.state.locations.map((favorite) => favorite.path), [
      '/two',
      '/one',
    ]);
  });
}
