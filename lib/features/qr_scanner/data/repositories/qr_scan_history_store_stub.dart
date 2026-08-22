import 'package:file_explorer/features/qr_scanner/data/repositories/in_memory_qr_scan_history_store.dart';
import 'package:file_explorer/features/qr_scanner/domain/repositories/qr_scan_history_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

QrScanHistoryStore createQrScanHistoryStore(Ref ref) {
  return InMemoryQrScanHistoryStore();
}
