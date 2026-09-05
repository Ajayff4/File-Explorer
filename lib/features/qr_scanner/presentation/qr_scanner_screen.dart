import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_explorer/app/theme/glass.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_provider.dart';
import 'package:file_explorer/features/media/presentation/local_media_actions.dart';
import 'package:file_explorer/features/qr_scanner/domain/entities/qr_scan.dart';
import 'package:file_explorer/features/qr_scanner/presentation/controllers/qr_scanner_controller.dart';
import 'package:file_explorer/features/qr_scanner/presentation/qr_image_builder.dart';
import 'package:file_explorer/features/qr_scanner/presentation/qr_output_directory_provider.dart';
import 'package:file_explorer/shared/widgets/folder_picker_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
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
                    GlassIconButton(
                      icon: Icons.photo_library_rounded,
                      tooltip: 'Scan from gallery',
                      onPressed: () {
                        _scanFromGallery();
                      },
                    ),
                    const SizedBox(width: 16),
                    GlassIconButton(
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
              color: Theme.of(context).colorScheme.surface,
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
  Uint8List? _qrBytes;
  bool _building = false;

  // Customization options.
  bool _useGradient = false;
  Color _foregroundColor = Colors.black;
  Color _gradientStart = Colors.deepPurple;
  Color _gradientEnd = Colors.blue;
  QrGradientDirection _gradientDirection = QrGradientDirection.diagonal;
  Color? _backgroundColor = Colors.white;
  bool _transparentBackground = false;
  QrTileStyle _tileStyle = QrTileStyle.dot;
  int _errorCorrection = QrErrorCorrectLevel.M;
  ui.Image? _logo;
  Uint8List? _logoBytes;
  double _logoFraction = 0.22;
  bool _pickingLogo = false;

  static const List<Color> _palette = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.amber,
    Colors.orange,
    Colors.brown,
    Colors.blueGrey,
  ];

  @override
  void dispose() {
    _textController.dispose();
    _logo?.dispose();
    super.dispose();
  }

  void _set(VoidCallback fn) {
    setState(fn);
    if (_data.isNotEmpty) unawaited(_buildQr());
  }

  int _highestErrorCorrection({
    required int base,
    required bool needsRobust,
  }) {
    return needsRobust ? math.max(base, QrErrorCorrectLevel.H) : base;
  }

  void _generate() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text == _data) return;
    setState(() => _data = text);
    unawaited(_buildQr());
    ref.read(qrScannerControllerProvider.notifier).addScan(
          content: text,
          format: 'QR code',
          type: QrScanType.generated,
        );
  }

  Future<void> _buildQr() async {
    if (_data.isEmpty) return;
    setState(() => _building = true);
    try {
      final effectiveEc = _highestErrorCorrection(
        base: _errorCorrection,
        needsRobust: _logo != null || _tileStyle == QrTileStyle.dot,
      );
      final bytes = await generateQrPng(
        data: _data,
        size: 1024,
        useGradient: _useGradient,
        foregroundColor: _foregroundColor,
        gradientStart: _gradientStart,
        gradientEnd: _gradientEnd,
        gradientDirection: _gradientDirection,
        backgroundColor:
            _transparentBackground ? null : (_backgroundColor ?? Colors.white),
        tileStyle: _tileStyle,
        logo: _logo,
        logoFraction: _logoFraction,
        errorCorrectionLevel: effectiveEc,
      );
      if (mounted) setState(() => _qrBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Could not generate QR: $e')),
          );
      }
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  Future<void> _pickLogo() async {
    if (_pickingLogo) return;
    setState(() => _pickingLogo = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      _logo?.dispose();
      setState(() {
        _logo = image;
        _logoBytes = bytes;
      });
      if (_data.isNotEmpty) unawaited(_buildQr());
    } finally {
      if (mounted) setState(() => _pickingLogo = false);
    }
  }

  void _removeLogo() {
    _logo?.dispose();
    setState(() {
      _logo = null;
      _logoBytes = null;
    });
    if (_data.isNotEmpty) unawaited(_buildQr());
  }

  Future<void> _saveQr() async {
    if (_qrBytes == null) return;
    final dir = ref.read(qrGeneratorOutputDirectoryProvider);
    try {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = '$dir/$fileName';
      await File(path).writeAsBytes(_qrBytes!);
      final mediaStore = ref.read(mediaStorePlatformProvider);
      if (mediaStore != null) {
        try {
          await mediaStore.scanFiles([path]);
        } catch (_) {
          // Rescan is best-effort.
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('QR saved to $dir'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => unawaited(openLocalFileWithSystem(path)),
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _shareQr() async {
    if (_qrBytes == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/qr_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(_qrBytes!);
      await shareLocalFile(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
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
    final hasQr = _qrBytes != null;

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
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_rounded),
          title: const Text('Save location'),
          subtitle: Text(
            ref.watch(qrGeneratorOutputDirectoryProvider),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: TextButton(
            onPressed: () async {
              final selected = await pickFolder(
                context,
                ref,
                currentPath: ref.read(qrGeneratorOutputDirectoryProvider),
              );
              if (selected != null && selected.isNotEmpty) {
                ref
                    .read(qrGeneratorOutputDirectoryProvider.notifier)
                    .setDirectory(selected);
              }
            },
            child: const Text('Change'),
          ),
        ),
        if (hasQr) ...[
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _transparentBackground
                    ? scheme.surfaceContainerHighest
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _building
                  ? const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Image.memory(_qrBytes!, width: 240, height: 240),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _saveQr,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _shareQr,
                tooltip: 'Share',
                icon: const Icon(Icons.share_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _copy,
                tooltip: 'Copy text',
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
        _buildOptions(),
        if (!hasQr) ...[
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Generate a QR code to preview and download it',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Colors', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Solid'),
              icon: Icon(Icons.square_rounded),
            ),
            ButtonSegment(
              value: true,
              label: Text('Gradient'),
              icon: Icon(Icons.gradient_rounded),
            ),
          ],
          selected: {_useGradient},
          onSelectionChanged: (selection) =>
              _set(() => _useGradient = selection.first),
        ),
        const SizedBox(height: 12),
        if (_useGradient) ...[
          Text('Gradient colors', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          _ColorTile(
            label: 'Start',
            selected: _gradientStart,
            palette: _palette,
            onChanged: (c) => _set(() => _gradientStart = c),
          ),
          const SizedBox(height: 6),
          _ColorTile(
            label: 'End',
            selected: _gradientEnd,
            palette: _palette,
            onChanged: (c) => _set(() => _gradientEnd = c),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<QrGradientDirection>(
            initialValue: _gradientDirection,
            decoration: const InputDecoration(
              labelText: 'Direction',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: QrGradientDirection.horizontal,
                child: Text('Horizontal'),
              ),
              DropdownMenuItem(
                value: QrGradientDirection.vertical,
                child: Text('Vertical'),
              ),
              DropdownMenuItem(
                value: QrGradientDirection.diagonal,
                child: Text('Diagonal'),
              ),
            ],
            onChanged: (value) => _set(() => _gradientDirection = value!),
          ),
        ] else ...[
          _ColorTile(
            label: 'Foreground',
            selected: _foregroundColor,
            palette: _palette,
            onChanged: (c) => _set(() => _foregroundColor = c),
          ),
        ],
        const SizedBox(height: 12),
        _ColorTile(
          label: 'Background',
          selected: _backgroundColor ?? Colors.white,
          palette: _palette,
          onChanged: (c) => _set(() {
            _backgroundColor = c;
            _transparentBackground = false;
          }),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Transparent background'),
          value: _transparentBackground,
          onChanged: (value) => _set(() => _transparentBackground = value),
        ),
        const Divider(),
        Text('Module style', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        SegmentedButton<QrTileStyle>(
          segments: const [
            ButtonSegment(
              value: QrTileStyle.square,
              label: Text('Square'),
              icon: Icon(Icons.grid_4x4_rounded),
            ),
            ButtonSegment(
              value: QrTileStyle.rounded,
              label: Text('Rounded'),
              icon: Icon(Icons.rounded_corner_rounded),
            ),
            ButtonSegment(
              value: QrTileStyle.dot,
              label: Text('Dots'),
              icon: Icon(Icons.circle_rounded),
            ),
          ],
          selected: {_tileStyle},
          onSelectionChanged: (selection) =>
              _set(() => _tileStyle = selection.first),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Error correction'),
          subtitle: const Text('Higher helps when using a logo'),
          trailing: DropdownButton<int>(
            value: _errorCorrection,
            items: const [
              DropdownMenuItem(
                value: QrErrorCorrectLevel.L,
                child: Text('Low'),
              ),
              DropdownMenuItem(
                value: QrErrorCorrectLevel.M,
                child: Text('Medium'),
              ),
              DropdownMenuItem(
                value: QrErrorCorrectLevel.Q,
                child: Text('Quartile'),
              ),
              DropdownMenuItem(
                value: QrErrorCorrectLevel.H,
                child: Text('High'),
              ),
            ],
            onChanged: (value) => _set(() => _errorCorrection = value!),
          ),
        ),
        const Divider(),
        Text('Center logo', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: _logoBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_logoBytes!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image_rounded),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: _pickingLogo ? null : _pickLogo,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Add logo'),
            ),
            if (_logoBytes != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _removeLogo,
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
          if (_logo != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(Icons.crop_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    label: 'Logo size',
                    value: _logoFraction,
                    min: 0.12,
                    max: 0.35,
                    divisions: 23,
                    onChanged: (value) => _set(() => _logoFraction = value),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A compact, collapsible color selector. Shows only the chosen color chip
/// until tapped; tapping reveals the fixed [palette] plus a custom entry that
/// opens a lightweight HSV picker. The panel collapses after a choice is made.
class _ColorTile extends StatefulWidget {
  const _ColorTile({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onChanged,
  });

  final String label;
  final Color selected;
  final List<Color> palette;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColorTile> createState() => _ColorTileState();
}

class _ColorTileState extends State<_ColorTile> {
  bool _expanded = false;

  Widget _swatch(Color color, bool active) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        widget.onChanged(color);
        setState(() => _expanded = false);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: active ? scheme.primary : Colors.grey.withValues(alpha: 0.6),
            width: active ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: widget.selected,
                    border: Border.all(color: scheme.outline),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.label)),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in widget.palette)
                  _swatch(color, color == widget.selected),
                InkWell(
                  onTap: () async {
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (_) => _CustomColorDialog(
                        initial: widget.selected,
                      ),
                    );
                    if (picked != null) {
                      widget.onChanged(picked);
                      setState(() => _expanded = false);
                    }
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outline),
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Minimal HSV color picker dialog (no external dependency).
class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.initial});

  final Color initial;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late double _h;
  late double _s;
  late double _v;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    _h = hsv.hue;
    _s = hsv.saturation;
    _v = hsv.value;
  }

  Color get _color =>
      HSVColor.fromAHSV(1, _h, _s, _v).toColor();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Custom color'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _color,
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            _hueSlider('Hue', _h, 0, 360, (value) => setState(() => _h = value)),
            _hueSlider('Saturation', _s, 0, 1, (value) => setState(() => _s = value)),
            _hueSlider('Brightness', _v, 0, 1, (value) => setState(() => _v = value)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _hueSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
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
        leading: GlassIconChip(
          icon: scan.type == QrScanType.generated
              ? Icons.qr_code_2_rounded
              : (isUrl ? Icons.link_rounded : Icons.text_fields_rounded),
          color: scheme.primary,
          size: 48,
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
