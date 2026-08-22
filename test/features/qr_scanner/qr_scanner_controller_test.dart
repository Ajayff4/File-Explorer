import 'package:file_explorer/features/qr_scanner/data/repositories/in_memory_qr_scan_history_store.dart';
import 'package:file_explorer/features/qr_scanner/domain/entities/qr_scan.dart';
import 'package:file_explorer/features/qr_scanner/presentation/controllers/qr_scanner_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads saved scans', () async {
    final store = InMemoryQrScanHistoryStore();
    await store.saveScan(
      QrScan(
        id: '1',
        content: 'https://example.com',
        format: 'QR code',
        scannedAt: DateTime(2026),
      ),
    );

    final controller = QrScannerController(store);
    await controller.loadHistory();

    expect(controller.state.scans.single.content, 'https://example.com');
  });

  test('adds a scan to the top of history', () async {
    final store = InMemoryQrScanHistoryStore();
    final controller = QrScannerController(store);

    await controller.addScan(content: 'one', format: 'QR code');
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await controller.addScan(content: 'two', format: 'QR code');

    expect(controller.state.scans.map((s) => s.content), ['two', 'one']);
    expect((await store.loadScans()).length, 2);
  });

  test('deletes a scan', () async {
    final store = InMemoryQrScanHistoryStore();
    final controller = QrScannerController(store);

    await controller.addScan(content: 'one', format: 'QR code');
    final id = controller.state.scans.single.id;

    await controller.deleteScan(id);

    expect(controller.state.scans, isEmpty);
    expect(await store.loadScans(), isEmpty);
  });

  test('clears history', () async {
    final store = InMemoryQrScanHistoryStore();
    final controller = QrScannerController(store);

    await controller.addScan(content: 'one', format: 'QR code');
    await controller.addScan(content: 'two', format: 'QR code');
    await controller.clearHistory();

    expect(controller.state.scans, isEmpty);
    expect(await store.loadScans(), isEmpty);
  });
}
