import 'package:drift/drift.dart';
import 'package:file_explorer/features/qr_scanner/domain/entities/qr_scan.dart';
import 'package:file_explorer/features/qr_scanner/domain/repositories/qr_scan_history_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftQrScanHistoryStore implements QrScanHistoryStore {
  const DriftQrScanHistoryStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<QrScan>> loadScans() async {
    final rows = await (_database.select(_database.qrScanRows)
          ..orderBy([(table) => OrderingTerm.desc(table.scannedAt)]))
        .get();
    return rows.map(_toScan).toList();
  }

  @override
  Future<void> saveScan(QrScan scan) {
    return _database
        .into(_database.qrScanRows)
        .insertOnConflictUpdate(_toCompanion(scan));
  }

  @override
  Future<void> deleteScan(String id) {
    return (_database.delete(_database.qrScanRows)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  @override
  Future<void> clearScans() {
    return _database.delete(_database.qrScanRows).go();
  }

  QrScan _toScan(QrScanRow row) {
    return QrScan(
      id: row.id,
      content: row.content,
      format: row.format,
      scannedAt: row.scannedAt,
      type: QrScanType.values.byName(row.type),
    );
  }

  QrScanRowsCompanion _toCompanion(QrScan scan) {
    return QrScanRowsCompanion.insert(
      id: scan.id,
      content: scan.content,
      format: scan.format,
      type: Value(scan.type.name),
      scannedAt: scan.scannedAt,
    );
  }
}
