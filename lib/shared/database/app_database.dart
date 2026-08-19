import 'package:drift/drift.dart';
import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
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
  BoolColumn get isFolder => boolean().withDefault(const Constant(true))();

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
  Set<Column<Object>> get primaryKey => {rootPath, path};
}

class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class DownloadTaskRows extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  IntColumn get mediaType => intEnum<DownloadMediaType>()();
  IntColumn get quality => intEnum<DownloadQuality>().nullable()();
  TextColumn get title => text().nullable()();
  IntColumn get status => intEnum<DownloadTaskStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get outputDirectory => text()();
  IntColumn get transferredBytes => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  RealColumn get speedBytesPerSecond => real().withDefault(const Constant(0))();
  TextColumn get fileName => text().nullable()();
  TextColumn get failureMessage => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    TransferTaskRows,
    FavoriteLocationRows,
    RecentLocationRows,
    SearchIndexEntryRows,
    SettingRows,
    DownloadTaskRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 9;

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
        if (from < 6) {
          await migrator.addColumn(
              recentLocationRows, recentLocationRows.isFolder);
        }
        if (from < 7) {
          // The search index used `path` as a single-column primary key. Since
          // entries are partitioned by rootPath, the same file path could be
          // indexed under multiple roots, violating the global UNIQUE on path.
          // Rebuild with a composite (rootPath, path) primary key.
          await customStatement('DROP TABLE IF EXISTS search_index_entry_rows');
          await migrator.createTable(searchIndexEntryRows);
        }
        if (from < 8) {
          await migrator.createTable(downloadTaskRows);
        }
        if (from < 9) {
          // `createTable`/`createAll` already materialize the current table
          // definition (which includes the quality column), so a fresh install
          // or a DB that skipped a version can reach this branch with the
          // column already present. Only add it when it is actually missing.
          final columns = await customSelect(
            "SELECT name FROM pragma_table_info('download_task_rows')",
          ).get();
          final hasQuality =
              columns.any((row) => row.read<String>('name') == 'quality');
          if (!hasQuality) {
            await migrator.addColumn(downloadTaskRows, downloadTaskRows.quality);
          }
        }
      },
    );
  }
}
