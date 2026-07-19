import 'package:file_explorer/features/recents/data/repositories/in_memory_recent_location_store.dart';
import 'package:file_explorer/features/recents/domain/entities/recent_location.dart';
import 'package:file_explorer/features/recents/presentation/controllers/recents_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads saved recents', () async {
    final store = InMemoryRecentLocationStore();
    final now = DateTime(2026);
    await store.saveRecent(
      RecentLocation(
        path: '/storage/emulated/0/Download',
        label: 'Download',
        openedAt: now,
      ),
    );

    final controller = RecentsController(store);
    await controller.loadRecents();

    expect(
        controller.state.locations.single.path, '/storage/emulated/0/Download');
  });

  test('records unique paths and increments open count', () async {
    final store = InMemoryRecentLocationStore();
    final controller = RecentsController(store);

    await controller.recordLocation(
      path: '/storage/emulated/0/Download',
      label: 'Download',
    );
    await controller.recordLocation(
      path: '/storage/emulated/0/Download',
      label: 'Downloads',
    );

    final recent = controller.state.locations.single;
    expect(recent.label, 'Downloads');
    expect(recent.openCount, 2);
    expect((await store.loadRecents()).single.openCount, 2);
  });

  test('records file history when requested', () async {
    final store = InMemoryRecentLocationStore();
    final controller = RecentsController(store);

    await controller.recordLocation(
      path: '/storage/emulated/0/Download/report.pdf',
      label: 'report.pdf',
      isFolder: false,
    );

    final recent = controller.state.locations.single;
    expect(recent.isFolder, isFalse);
    expect((await store.loadRecents()).single.isFolder, isFalse);
  });

  test('removes and clears recents', () async {
    final store = InMemoryRecentLocationStore();
    final controller = RecentsController(store);

    await controller.recordLocation(path: '/one', label: 'One');
    await controller.recordLocation(path: '/two', label: 'Two');
    await controller.removeRecent('/one');

    expect(controller.state.locations.map((recent) => recent.path), ['/two']);

    await controller.clearRecents();

    expect(controller.state.locations, isEmpty);
    expect(await store.loadRecents(), isEmpty);
  });

  test('newer recents sort first', () async {
    final store = InMemoryRecentLocationStore();
    final controller = RecentsController(store);

    await controller.recordLocation(path: '/one', label: 'One');
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await controller.recordLocation(path: '/two', label: 'Two');

    expect(controller.state.locations.map((recent) => recent.path), [
      '/two',
      '/one',
    ]);
  });
}
