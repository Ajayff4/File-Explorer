import 'package:file_explorer/features/qr_scanner/data/repositories/drift_qr_scan_history_store.dart';
import 'package:file_explorer/features/qr_scanner/domain/repositories/qr_scan_history_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

QrScanHistoryStore createQrScanHistoryStore(Ref ref) {
  return DriftQrScanHistoryStore(ref.watch(appDatabaseProvider));
}
