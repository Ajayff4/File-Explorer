import 'package:file_explorer/features/qr_scanner/domain/entities/qr_scan.dart';
import 'package:file_explorer/features/qr_scanner/domain/repositories/qr_scan_history_store.dart';

class InMemoryQrScanHistoryStore implements QrScanHistoryStore {
  final Map<String, QrScan> _scans = {};

  @override
  Future<List<QrScan>> loadScans() async {
    final scans = _scans.values.toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return scans;
  }

  @override
  Future<void> saveScan(QrScan scan) async {
    _scans[scan.id] = scan;
  }

  @override
  Future<void> deleteScan(String id) async {
    _scans.remove(id);
  }

  @override
  Future<void> clearScans() async {
    _scans.clear();
  }
}
