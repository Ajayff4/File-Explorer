import 'dart:async';

import 'package:file_explorer/features/qr_scanner/data/repositories/qr_scan_history_store_provider.dart';
import 'package:file_explorer/features/qr_scanner/domain/entities/qr_scan.dart';
import 'package:file_explorer/features/qr_scanner/domain/repositories/qr_scan_history_store.dart';
import 'package:flutter_riverpod/legacy.dart';

final qrScannerControllerProvider =
    StateNotifierProvider<QrScannerController, QrScannerState>((ref) {
  final controller = QrScannerController(ref.read(qrScanHistoryStoreProvider));
  unawaited(controller.loadHistory());
  return controller;
});

class QrScannerState {
  const QrScannerState({
    this.scans = const [],
    this.isLoading = false,
  });

  final List<QrScan> scans;
  final bool isLoading;

  QrScannerState copyWith({
    List<QrScan>? scans,
    bool? isLoading,
  }) {
    return QrScannerState(
      scans: scans ?? this.scans,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class QrScannerController extends StateNotifier<QrScannerState> {
  QrScannerController(this._store) : super(const QrScannerState());

  final QrScanHistoryStore _store;

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    final scans = await _store.loadScans();
    if (!mounted) return;
    state = state.copyWith(scans: scans, isLoading: false);
  }

  Future<void> addScan({
    required String content,
    required String format,
    QrScanType type = QrScanType.scanned,
  }) async {
    final scan = QrScan(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      format: format,
      scannedAt: DateTime.now(),
      type: type,
    );
    await _store.saveScan(scan);
    if (!mounted) return;
    state = state.copyWith(scans: _prepend(scan));
  }

  Future<void> deleteScan(String id) async {
    await _store.deleteScan(id);
    if (!mounted) return;
    state = state.copyWith(
      scans: [
        for (final scan in state.scans)
          if (scan.id != id) scan,
      ],
    );
  }

  Future<void> clearHistory() async {
    await _store.clearScans();
    if (!mounted) return;
    state = state.copyWith(scans: const []);
  }

  List<QrScan> _prepend(QrScan scan) {
    return [scan, ...state.scans];
  }
}
