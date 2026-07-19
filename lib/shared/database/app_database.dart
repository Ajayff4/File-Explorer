import 'package:drift/drift.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';

part 'app_database.g.dart';

class TransferTaskRows extends Table {
  TextColumn get id => text()();
  IntColumn get operation => intEnum<TransferOperation>()();
  TextColumn get sourcePathsJson => text()();
  TextColumn get displayName => text()();
  IntColumn get status => intEnum<TransferTaskStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get destinationPath => text().nullable()();
  IntColumn get transferredBytes => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  TextColumn get currentItemPath => text().nullable()();
  IntColumn get conflictPolicy => intEnum<ConflictPolicy>()();
  TextColumn get failureMessage => text().nullable()();
  IntColumn get failureCode => intEnum<TransferFailureCode>().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FavoriteLocationRows extends Table {
  TextColumn get path => text()();
  TextColumn get label => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

class RecentLocationRows extends Table {
  TextColumn get path => text()();
  TextColumn get label => text()();
  DateTimeColumn get openedAt => dateTime()();
  IntColumn get openCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

class SearchIndexEntryRows extends Table {
  TextColumn get path => text()();
  TextColumn get rootPath => text()();
  TextColumn get parentPath => text()();
  TextColumn get name => text()();
  IntColumn get type => intEnum<FileSystemEntryType>()();
  DateTimeColumn get modifiedAt => dateTime()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get childrenCount => integer().nullable()();
  IntColumn get depth => integer()();
  DateTimeColumn get indexedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    TransferTaskRows,
    FavoriteLocationRows,
    RecentLocationRows,
    SearchIndexEntryRows,
    SettingRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(favoriteLocationRows);
        }
        if (from < 3) {
          await migrator.createTable(recentLocationRows);
        }
        if (from < 4) {
          await migrator.createTable(searchIndexEntryRows);
        }
        if (from < 5) {
          await migrator.createTable(settingRows);
        }
      },
    );
  }
}
