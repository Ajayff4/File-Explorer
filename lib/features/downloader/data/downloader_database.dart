import 'package:drift/drift.dart';
import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';

part 'downloader_database.g.dart';

class DownloadTaskRows extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  IntColumn get mediaType => intEnum<DownloadMediaType>()();
  IntColumn get quality => intEnum<DownloadQuality>().nullable()();
  IntColumn get audioFormat =>
      intEnum<DownloadAudioFormat>().withDefault(const Constant(0))();
  BoolColumn get playlist => boolean().withDefault(const Constant(false))();
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

/// Feature-local database for the Universal Downloader. Kept out of the shared
/// [AppDatabase] so that, in the `standard` (Play Store) flavor, the entire
/// downloader graph — including this table, its `download_task_rows` name, and
/// its column names — is tree-shaken and leaves no trace.
@DriftDatabase(tables: [DownloadTaskRows])
class DownloaderDatabase extends _$DownloaderDatabase {
  DownloaderDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
