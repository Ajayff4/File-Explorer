import 'package:file_explorer/features/recents/domain/entities/recent_location.dart';

abstract interface class RecentLocationStore {
  Future<List<RecentLocation>> loadRecents();
  Future<void> saveRecent(RecentLocation recent);
  Future<void> deleteRecent(String path);
  Future<void> clearRecents();
}
