import 'package:file_explorer/features/qr_scanner/data/repositories/qr_scan_history_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/qr_scanner/data/repositories/qr_scan_history_store_io.dart';
import 'package:file_explorer/features/qr_scanner/domain/repositories/qr_scan_history_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final qrScanHistoryStoreProvider = Provider<QrScanHistoryStore>((ref) {
  return createQrScanHistoryStore(ref);
});
