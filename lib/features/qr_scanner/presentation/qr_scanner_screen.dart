import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/qr_scanner/domain/entities/qr_scan.dart';
import 'package:file_explorer/features/qr_scanner/presentation/controllers/qr_scanner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR scanner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scan'),
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Generate'),
            Tab(icon: Icon(Icons.history_rounded), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ScanTab(),
          _GenerateTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

class _ScanTab extends ConsumerStatefulWidget {
  const _ScanTab();

  @override
  ConsumerState<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends ConsumerState<_ScanTab> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final value = _controller.value;
    if (!value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed) {
      if (!value.isRunning) _controller.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (value.isRunning) _controller.stop();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handling) return;
    final barcode = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.firstWhere(
            (b) => (b.rawValue ?? b.displayValue)?.isNotEmpty == true,
            orElse: () => capture.barcodes.first,
          );
    final content = barcode?.rawValue ?? barcode?.displayValue;
    if (content == null || content.isEmpty) return;

    _handling = true;
    _controller.stop();
    _recordAndShow(context, content, barcode!.format);
  }

  void _resume() {
    setState(() => _handling = false);
    _controller.start();
  }

  Future<void> _scanFromGallery() async {
    if (_handling) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _handling = true);
    try {
      final capture = await _controller.analyzeImage(picked.path);
      if (!mounted) return;
      final barcode = capture == null || capture.barcodes.isEmpty
          ? null
          : capture.barcodes.firstWhere(
              (b) => (b.rawValue ?? b.displayValue)?.isNotEmpty == true,
              orElse: () => capture.barcodes.first,
            );
      final content = barcode?.rawValue ?? barcode?.displayValue;
      if (content == null || content.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('No QR code found in image')),
            );
        }
        _resume();
        return;
      }
      await _recordAndShow(context, content, barcode!.format);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Could not read image: $e')),
          );
      }
      _resume();
    }
  }

  Future<void> _recordAndShow(
    BuildContext context,
    String content,
    BarcodeFormat format,
  ) async {
    await ref
        .read(qrScannerControllerProvider.notifier)
        .addScan(content: content, format: _formatLabel(format));
    if (!mounted || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _ScanResultSheet(
        content: content,
        onScanAgain: _resume,
      ),
    );
    if (mounted) {
      _resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, value, _) {
        final scanner = Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              overlayBuilder: (context, constraints) {
                return _ScannerOverlay(scheme: scheme);
              },
            ),
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeumorphicIconButton(
                      icon: Icons.photo_library_rounded,
                      tooltip: 'Scan from gallery',
                      onPressed: () {
                        _scanFromGallery();
                      },
                    ),
                    const SizedBox(width: 16),
                    NeumorphicIconButton(
                      icon: value.torchState == TorchState.on
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      tooltip: value.torchState == TorchState.on
                          ? 'Turn flash off'
                          : 'Turn flash on',
                      onPressed: _controller.toggleTorch,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        if (value.error == null) return scanner;

        return Stack(
          fit: StackFit.expand,
          children: [
            scanner,
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _CameraDeniedView(error: value.error),
            ),
          ],
        );
      },
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({
    required this.content,
    required this.onScanAgain,
  });

  final String content;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUrl = _looksLikeUrl(content);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Code found',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                content,
                maxLines: 6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                ),
                if (isUrl) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openUrl(context),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onScanAgain();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Scan another'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.parse(content);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }
}

class _GenerateTab extends ConsumerStatefulWidget {
  const _GenerateTab();

  @override
  ConsumerState<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends ConsumerState<_GenerateTab> {
  final TextEditingController _textController = TextEditingController();
  String _data = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _generate() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text == _data) return;
    setState(() => _data = text);
    ref.read(qrScannerControllerProvider.notifier).addScan(
          content: text,
          format: 'QR code',
          type: QrScanType.generated,
        );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _data));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Text copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _textController,
          minLines: 1,
          maxLines: 4,
          onSubmitted: (_) => _generate(),
          decoration: const InputDecoration(
            hintText: 'Enter text or a link',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text('Generate QR code'),
        ),
        if (_data.isNotEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: _data,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy text'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 48),
          Icon(
            Icons.qr_code_2_rounded,
            size: 64,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Enter text to generate a QR code',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrScannerControllerProvider);
    final controller = ref.read(qrScannerControllerProvider.notifier);
    final scans = state.scans;

    if (state.isLoading && scans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (scans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('No scans yet'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextButton.icon(
              onPressed: controller.clearHistory,
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Clear history'),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: scans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final scan = scans[index];
              return _HistoryTile(
                scan: scan,
                onDelete: () => controller.deleteScan(scan.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.scan,
    required this.onDelete,
  });

  final QrScan scan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUrl = _looksLikeUrl(scan.content);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          scan.type == QrScanType.generated
              ? Icons.qr_code_2_rounded
              : (isUrl ? Icons.link_rounded : Icons.text_fields_rounded),
          color: scheme.primary,
        ),
        title: Text(
          scan.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                '${scan.format} · ${formatRelativeDate(scan.scannedAt)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _scanTypeBadge(scan.type, scheme),
          ],
        ),
        onTap: () => _showActions(context, isUrl),
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: onDelete,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }

  Widget _scanTypeBadge(QrScanType type, ColorScheme scheme) {
    final generated = type == QrScanType.generated;
    final color = generated ? scheme.tertiary : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        generated ? 'Generated' : 'Scanned',
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, bool isUrl) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SelectableText(scan.content),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _copy(context);
              },
            ),
            if (isUrl)
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open link'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  launchUrl(
                    Uri.parse(scan.content),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: scan.content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.primary, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _CameraDeniedView extends StatelessWidget {
  const _CameraDeniedView({this.error});

  final MobileScannerException? error;

  @override
  Widget build(BuildContext context) {
    final denied = error?.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              denied
                  ? Icons.no_photography_rounded
                  : Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              denied
                  ? 'Camera permission is required to scan QR codes'
                  : 'Camera could not be started',
              textAlign: TextAlign.center,
            ),
            if (denied) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NeumorphicIconButton extends StatelessWidget {
  const NeumorphicIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

String _formatLabel(BarcodeFormat format) {
  return switch (format) {
    BarcodeFormat.qrCode => 'QR code',
    BarcodeFormat.code128 => 'Code 128',
    BarcodeFormat.code39 => 'Code 39',
    BarcodeFormat.ean13 => 'EAN-13',
    BarcodeFormat.ean8 => 'EAN-8',
    BarcodeFormat.upcA => 'UPC-A',
    BarcodeFormat.upcE => 'UPC-E',
    BarcodeFormat.aztec => 'Aztec',
    BarcodeFormat.dataMatrix => 'Data Matrix',
    BarcodeFormat.pdf417 => 'PDF-417',
    BarcodeFormat.itf14 => 'ITF-14',
    BarcodeFormat.codabar => 'Codabar',
    BarcodeFormat.code93 => 'Code 93',
    BarcodeFormat.microQrCode => 'Micro QR',
    _ => 'Barcode',
  };
}

bool _looksLikeUrl(String content) {
  final uri = Uri.tryParse(content);
  if (uri == null) return false;
  return uri.scheme == 'http' || uri.scheme == 'https';
}
