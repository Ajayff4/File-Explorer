import 'dart:io';

import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_peer.dart';
import 'package:file_explorer/features/nearby_sharing/data/protocol/nearby_protocol.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_transfer_file.dart';
import 'package:file_explorer/features/nearby_sharing/presentation/controllers/nearby_output_directory_provider.dart';
import 'package:file_explorer/features/nearby_sharing/presentation/controllers/nearby_sharing_controller.dart';
import 'package:file_explorer/features/nearby_sharing/shared/local_ip.dart';
import 'package:file_explorer/shared/widgets/folder_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Screen for device-to-device sharing. [initialPaths] (from Explorer's
/// "Send nearby" action) seeds the files to send.
class NearbyShareScreen extends ConsumerStatefulWidget {
  const NearbyShareScreen({super.key, this.initialPaths = const []});

  final List<String> initialPaths;

  @override
  ConsumerState<NearbyShareScreen> createState() => _NearbyShareScreenState();
}

class _NearbyShareScreenState extends ConsumerState<NearbyShareScreen> {
  late List<NearbyOutgoingFile> _pendingFiles;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _pendingFiles = _expandToFiles(widget.initialPaths);
  }

  NearbyOutgoingFile _toOutgoingFile(String path, {String? relativePath}) {
    final name = p.basename(path);
    var size = 0;
    try {
      size = File(path).lengthSync();
    } catch (_) {}
    return NearbyOutgoingFile(
      id: path,
      path: path,
      name: name,
      size: size,
      relativePath: relativePath,
    );
  }

  /// Expands the selected paths so folders become their contained files,
  /// preserving the folder name as the start of each file's relative path.
  List<NearbyOutgoingFile> _expandToFiles(List<String> paths) {
    final result = <NearbyOutgoingFile>[];
    for (final path in paths) {
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.directory) {
        final baseName = p.basename(path);
        try {
          for (final entity in Directory(path).listSync(recursive: true)) {
            if (entity is File) {
              final rel = p.relative(entity.path, from: path);
              result.add(
                _toOutgoingFile(entity.path, relativePath: p.join(baseName, rel)),
              );
            }
          }
        } on FileSystemException {
          // Skip folders we cannot read.
        }
      } else if (type == FileSystemEntityType.file) {
        result.add(_toOutgoingFile(path));
      }
    }
    return result;
  }

  void _addFiles(List<String> paths) {
    setState(() {
      final existing = _pendingFiles.map((f) => f.path).toSet();
      _pendingFiles = [
        ..._pendingFiles,
        for (final file in _expandToFiles(paths))
          if (!existing.contains(file.path)) file,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbySharingControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<NearbySharingState>(nearbySharingControllerProvider,
        (prev, next) {
      final wasSending = prev?.mode == NearbyMode.sending;
      final finishedIdle = next.mode == NearbyMode.idle;
      final successful = next.error == null;
      if (wasSending && finishedIdle && successful && mounted) {
        setState(() => _pendingFiles = const []);
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Share'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: 'Connection info',
              onPressed: () => _showConnectionInfo(context, ref),
            ),
          ],
          bottom: TabBar(
            onTap: (i) => setState(() => _tab = i),
            tabs: const [
              Tab(icon: Icon(Icons.download_rounded), text: 'Receive'),
              Tab(icon: Icon(Icons.upload_rounded), text: 'Send'),
            ],
          ),
        ),
        body: _tab == 0
            ? _ReceiveTab(state: state, scheme: scheme)
            : _SendTab(
                state: state,
                scheme: scheme,
                pendingFiles: _pendingFiles,
                onRemovePending: (file) =>
                    setState(() => _pendingFiles.remove(file)),
                onScan: () => ref
                    .read(nearbySharingControllerProvider.notifier)
                    .startScan(),
                onStopScan: () => ref
                    .read(nearbySharingControllerProvider.notifier)
                    .stopScan(),
                onAddFiles: _addFiles,
                onSend: (peer) => ref
                    .read(nearbySharingControllerProvider.notifier)
                    .sendToPeer(peer, _pendingFiles),
      ),
    ),
    );
  }

  void _showConnectionInfo(BuildContext context, WidgetRef ref) {
    final selfName = ref.read(nearbySharingControllerProvider).selfName;
    final port = NearbyProtocol.tcpPort;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        title: const Text('Connection info'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoLine('Device name', selfName),
              FutureBuilder<String>(
                future: getLanIpAddress(),
                builder: (context, snap) =>
                    _infoLine('IP address', snap.data ?? 'Resolving…'),
              ),
              _infoLine('Port', '$port'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

class _ReceiveTab extends ConsumerWidget {
  const _ReceiveTab({required this.state, required this.scheme});

  final NearbySharingState state;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(nearbySharingControllerProvider.notifier);
    final saveDir = ref.watch(nearbyOutputDirectoryProvider);
    final incoming = state.transfers
        .where((t) => t.direction == TransferDirection.incoming)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Both devices must be on the same Wi-Fi network.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_rounded),
            title: const Text('Save received files to'),
            subtitle: Text(
              saveDir,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TextButton(
              onPressed: () async {
                final selected = await pickFolder(
                  context,
                  ref,
                  currentPath: saveDir,
                );
                if (selected != null && selected.isNotEmpty) {
                  ref
                      .read(nearbyOutputDirectoryProvider.notifier)
                      .setDirectory(selected);
                }
              },
              child: const Text('Change'),
            ),
          ),
          const SizedBox(height: 8),
          if (!state.hosting) ...[
            FilledButton.icon(
              onPressed: () => notifier.startHosting(
                destinationDir: saveDir,
              ),
              icon: const Icon(Icons.wifi_rounded),
              label: const Text('Start receiving'),
            ),
          ] else ...[
            NeumorphicCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Ready to receive',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The sender will connect automatically.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => notifier.stopHosting(),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop receiving'),
            ),
          ],
          const SizedBox(height: 16),
          if (state.error != null)
            Text(state.error!, style: TextStyle(color: scheme.error)),
          const SizedBox(height: 8),
          Expanded(
            child: incoming.isEmpty
                ? const Center(child: Text('No incoming transfers yet'))
                : ListView.builder(
                    itemCount: incoming.length,
                    itemBuilder: (context, i) =>
                        _TransferTile(item: incoming[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SendTab extends ConsumerWidget {
  const _SendTab({
    required this.state,
    required this.scheme,
    required this.pendingFiles,
    required this.onRemovePending,
    required this.onScan,
    required this.onStopScan,
    required this.onAddFiles,
    required this.onSend,
  });

  final NearbySharingState state;
  final ColorScheme scheme;
  final List<NearbyOutgoingFile> pendingFiles;
  final void Function(NearbyOutgoingFile) onRemovePending;
  final VoidCallback onScan;
  final VoidCallback onStopScan;
  final void Function(List<String>) onAddFiles;
  final void Function(NearbyPeer) onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoing = state.transfers
        .where((t) => t.direction == TransferDirection.outgoing)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push<List<String>>(
                MaterialPageRoute(
                  builder: (_) => ExplorerScreen(
                    pickerMode: true,
                    pickerTitle: 'Select files to send',
                  ),
                ),
              );
              if (result != null && result.isNotEmpty) {
                onAddFiles(result);
              }
            },
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Select files'),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pendingFiles.isEmpty)
                    const SizedBox(
                      height: 240,
                      child: Center(
                        child: Text(
                          'Pick files and folders to send, then scan for a device.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else ...[
                    Text('Selected files',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final file in pendingFiles)
                      ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(file.name),
                        subtitle: Text(_bytes(file.size)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => onRemovePending(file),
                        ),
                      ),
                  ],
                  if (outgoing.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Transfers',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final item in outgoing) _TransferTile(item: item),
                    if (state.mode == NearbyMode.sending)
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(nearbySharingControllerProvider.notifier)
                            .cancelSend(),
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text('Cancel'),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (state.mode != NearbyMode.sending) ...[
            if (!state.scanning)
              FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.radar_rounded),
                label: const Text('Scan for devices'),
              )
            else
              OutlinedButton.icon(
                onPressed: onStopScan,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop scanning'),
              ),
            const SizedBox(height: 8),
            _ReceiverAccordion(
              peers: state.peers,
              scanning: state.scanning,
              onSend: onSend,
            ),
          ],
        ],
      ),
    );
}
}

class _ReceiverAccordion extends StatefulWidget {
  const _ReceiverAccordion({
    required this.peers,
    required this.scanning,
    required this.onSend,
  });

  final List<NearbyPeer> peers;
  final bool scanning;
  final void Function(NearbyPeer) onSend;

  @override
  State<_ReceiverAccordion> createState() => _ReceiverAccordionState();
}

class _ReceiverAccordionState extends State<_ReceiverAccordion> {
  var _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.devices_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.peers.isEmpty
                          ? 'Nearby devices'
                          : 'Nearby devices (${widget.peers.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    _collapsed
                        ? Icons.expand_more_rounded
                        : Icons.expand_less_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (!_collapsed) ...[
            if (widget.peers.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.peers.length,
                itemBuilder: (context, i) {
                  final peer = widget.peers[i];
                  return ListTile(
                    leading: const Icon(Icons.phone_android_rounded),
                    title: Text(peer.name),
                    subtitle: Text(peer.host),
                    trailing: const Icon(Icons.send_rounded),
                    onTap: () => widget.onSend(peer),
                  );
                },
              )
            else if (widget.scanning)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: Text('Looking for nearby devices…')),
              ),
          ],
        ],
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({required this.item});

  final NearbyTransferItem item;

  @override
  Widget build(BuildContext context) {
    final total = item.totalBytes ?? item.size;
    final fraction = total > 0
        ? (item.transferredBytes / total).clamp(0.0, 1.0)
        : null;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: item.ok == true
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : item.ok == false
              ? Icon(Icons.error_rounded, color: scheme.error)
              : const Icon(Icons.sync_rounded),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: fraction),
          const SizedBox(height: 4),
          Text(
            item.ok == false
                ? 'Failed'
                : '${_bytes(item.transferredBytes)} / ${_bytes(total)}',
          ),
        ],
      ),
    );
  }
}

String _bytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(1)} ${units[unit]}';
}
