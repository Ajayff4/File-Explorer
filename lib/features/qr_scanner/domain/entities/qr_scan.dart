/// How a QR history entry was created.
enum QrScanType {
  /// Decoded from a live camera scan or a gallery image.
  scanned,

  /// Produced by the "Generate" tab.
  generated,
}

/// A single past scan kept in the QR scanner history.
class QrScan {
  const QrScan({
    required this.id,
    required this.content,
    required this.format,
    required this.scannedAt,
    this.type = QrScanType.scanned,
  });

  /// Unique id (also the drift primary key).
  final String id;

  /// The decoded text/URL carried by the code.
  final String content;

  /// Human-readable barcode format name (e.g. "QR code").
  final String format;

  final DateTime scannedAt;

  /// Whether this entry was scanned or generated.
  final QrScanType type;
}
