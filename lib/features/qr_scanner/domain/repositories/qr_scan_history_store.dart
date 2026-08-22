import 'package:file_explorer/features/qr_scanner/domain/entities/qr_scan.dart';

abstract interface class QrScanHistoryStore {
  Future<List<QrScan>> loadScans();
  Future<void> saveScan(QrScan scan);
  Future<void> deleteScan(String id);
  Future<void> clearScans();
}
