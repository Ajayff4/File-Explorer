import 'package:drift/drift.dart';
import 'package:file_explorer/features/recents/domain/entities/recent_location.dart';
import 'package:file_explorer/features/recents/domain/repositories/recent_location_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftRecentLocationStore implements RecentLocationStore {
  const DriftRecentLocationStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<RecentLocation>> loadRecents() async {
    final rows = await (_database.select(_database.recentLocationRows)
          ..orderBy([
            (table) => OrderingTerm.desc(table.openedAt),
          ]))
        .get();
    return rows.map(_toRecent).toList();
  }

  @override
  Future<void> saveRecent(RecentLocation recent) {
    return _database
        .into(_database.recentLocationRows)
        .insertOnConflictUpdate(_toCompanion(recent));
  }

  @override
  Future<void> deleteRecent(String path) {
    return (_database.delete(_database.recentLocationRows)
          ..where((table) => table.path.equals(path)))
        .go();
  }

  @override
  Future<void> clearRecents() {
    return _database.delete(_database.recentLocationRows).go();
  }

  RecentLocation _toRecent(RecentLocationRow row) {
    return RecentLocation(
      path: row.path,
      label: row.label,
      openedAt: row.openedAt,
      openCount: row.openCount,
      isFolder: row.isFolder,
    );
  }

  RecentLocationRowsCompanion _toCompanion(RecentLocation recent) {
    return RecentLocationRowsCompanion.insert(
      path: recent.path,
      label: recent.label,
      openedAt: recent.openedAt,
      openCount: Value(recent.openCount),
      isFolder: Value(recent.isFolder),
    );
  }
}
