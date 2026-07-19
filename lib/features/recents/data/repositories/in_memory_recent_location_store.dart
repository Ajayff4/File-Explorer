import 'package:file_explorer/features/recents/domain/entities/recent_location.dart';
import 'package:file_explorer/features/recents/domain/repositories/recent_location_store.dart';

class InMemoryRecentLocationStore implements RecentLocationStore {
  final Map<String, RecentLocation> _recents = {};

  @override
  Future<List<RecentLocation>> loadRecents() async {
    final recents = _recents.values.toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return recents;
  }

  @override
  Future<void> saveRecent(RecentLocation recent) async {
    _recents[recent.path] = recent;
  }

  @override
  Future<void> deleteRecent(String path) async {
    _recents.remove(path);
  }

  @override
  Future<void> clearRecents() async {
    _recents.clear();
  }
}
