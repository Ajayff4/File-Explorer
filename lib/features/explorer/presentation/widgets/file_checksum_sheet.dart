import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/services/file_checksum_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showFileChecksumSheet(BuildContext context, FileSystemEntry entry) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _FileChecksumSheet(entry: entry),
  );
}

class _FileChecksumSheet extends StatefulWidget {
  const _FileChecksumSheet({required this.entry});

  final FileSystemEntry entry;

  @override
  State<_FileChecksumSheet> createState() => _FileChecksumSheetState();
}

class _FileChecksumSheetState extends State<_FileChecksumSheet> {
  static const _service = FileChecksumService();

  late Future<List<FileChecksum>> _checksums;

  @override
  void initState() {
    super.initState();
    _checksums = _compute();
  }

  Future<List<FileChecksum>> _compute() {
    return _service.compute(widget.entry.path);
  }

  void _retry() {
    setState(() => _checksums = _compute());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.fingerprint_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checksums',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          widget.entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<FileChecksum>>(
                future: _checksums,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Computing checksums...'),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      error: snapshot.error!,
                      onRetry: _retry,
                    );
                  }
                  final checksums = snapshot.data ?? const <FileChecksum>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final checksum in checksums) ...[
                        _ChecksumTile(checksum: checksum),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => _copyAll(context, checksums),
                        icon: const Icon(Icons.copy_all_rounded),
                        label: const Text('Copy all'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Computed locally on this device. No data is uploaded.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyAll(
    BuildContext context,
    List<FileChecksum> checksums,
  ) async {
    final text = checksums
        .map((checksum) => '${checksum.algorithm.label}: ${checksum.digest}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All checksums copied')),
    );
  }
}

class _ChecksumTile extends StatelessWidget {
  const _ChecksumTile({required this.checksum});

  final FileChecksum checksum;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                checksum.algorithm.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copy ${checksum.algorithm.label}',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: checksum.digest));
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${checksum.algorithm.label} copied'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
          SelectableText(
            checksum.digest,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'Could not compute checksums',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
