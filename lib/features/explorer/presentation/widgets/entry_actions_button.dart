import 'dart:io';

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/presentation/local_media_actions.dart';
import 'package:file_explorer/features/media/presentation/media_viewer_screen.dart';
import 'package:file_explorer/features/media/presentation/text_file_viewer_screen.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_visuals.dart';
import 'package:file_explorer/shared/archive/archive_format.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:file_explorer/shared/formatters/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

enum _CompressionChoice {
  zip(
    label: 'ZIP',
    subtitle: 'Works with files, folders, and selections',
    extension: '.zip',
    icon: Icons.inventory_2_rounded,
    emoji: '📦',
    supportsLevel: true,
    supportsPassword: true,
  ),
  tar(
    label: 'TAR',
    subtitle: 'Archive files and folders without compression',
    extension: '.tar',
    icon: Icons.folder_zip_rounded,
    emoji: '🗃️',
  ),
  gzip(
    label: 'GZ',
    subtitle: 'Single-file compression',
    extension: '.gz',
    icon: Icons.compress_rounded,
    emoji: '💨',
    supportsLevel: true,
    singleFileOnly: true,
  ),
  tarGzip(
    label: 'TAR.GZ',
    subtitle: 'Good for folders and multi-file selections',
    extension: '.tar.gz',
    icon: Icons.inventory_rounded,
    emoji: '🗜️',
    supportsLevel: true,
  ),
  tarBzip2(
    label: 'TAR.BZ2',
    subtitle: 'Good for folders and multi-file selections',
    extension: '.tar.bz2',
    icon: Icons.inventory_rounded,
    emoji: '🧱',
  ),
  tarXz(
    label: 'TAR.XZ',
    subtitle: 'Good for folders and multi-file selections',
    extension: '.tar.xz',
    icon: Icons.inventory_rounded,
    emoji: '💎',
  );

  const _CompressionChoice({
    required this.label,
    required this.subtitle,
    required this.extension,
    required this.icon,
    required this.emoji,
    this.supportsLevel = false,
    this.supportsPassword = false,
    this.singleFileOnly = false,
  });

  final String label;
  final String subtitle;
  final String extension;
  final IconData icon;
  final String emoji;
  final bool supportsLevel;
  final bool supportsPassword;
  final bool singleFileOnly;
}

enum _CompressionLevel {
  store(label: 'Store', level: 0),
  fast(label: 'Fast', level: 1),
  standard(label: 'Standard', level: 6),
  best(label: 'Best', level: 9);

  const _CompressionLevel({
    required this.label,
    required this.level,
  });

  final String label;
  final int level;
}

class _CompressionOptions {
  const _CompressionOptions({
    required this.fileName,
    required this.choice,
    required this.level,
    this.password,
  });

  final String fileName;
  final _CompressionChoice choice;
  final _CompressionLevel level;
  final String? password;
}

class EntryActionsButton extends ConsumerWidget {
  const EntryActionsButton({
    required this.entry,
    this.storageVolume,
    this.isSingleSelection = true,
    super.key,
  });

  final FileSystemEntry entry;
  final StorageVolume? storageVolume;
  final bool isSingleSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'More',
      onPressed: () => showEntryActionsSheet(
        context: context,
        ref: ref,
        entry: entry,
        storageVolume: storageVolume,
        isSingleSelection: isSingleSelection,
      ),
      icon: const Icon(Icons.more_vert_rounded),
    );
  }
}

void showEntryActionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required FileSystemEntry entry,
  StorageVolume? storageVolume,
  bool isSingleSelection = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return _EntryActionsSheet(
        entry: entry,
        storageVolume: storageVolume,
        parentContext: context,
        isSingleSelection: isSingleSelection,
      );
    },
  );
}

enum _OpenAsType {
  text('Text', Icons.article_rounded, 'text/plain'),
  image('Image', Icons.image_rounded, 'image/*'),
  video('Video', Icons.movie_rounded, 'video/*'),
  audio('Audio', Icons.music_note_rounded, 'audio/*');

  const _OpenAsType(this.label, this.icon, this.mimeType);
  final String label;
  final IconData icon;
  final String mimeType;
}

void showOpenAsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required FileSystemEntry entry,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: fileIconForEntry(context, entry),
              title: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text('Open as'),
            ),
            const Divider(),
            for (final type in _OpenAsType.values)
              ListTile(
                leading: Icon(type.icon),
                title: Text(type.label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEntryAs(context, ref, entry, type);
                },
              ),
          ],
        ),
      );
    },
  );
}

/// Opens [entry] in the best available built-in viewer.
///
/// Routes previewable media to the media viewer, text to the text viewer and
/// browsable archives to the archive viewer. When none applies (preview not
/// available) a sheet with "Open with" / "Open as" is shown instead.
void openFileForPreview({
  required BuildContext context,
  required WidgetRef ref,
  required FileSystemEntry entry,
  List<FileSystemEntry> playlist = const [],
}) {
  final type = entry.type;
  if (type == FileSystemEntryType.image ||
      type == FileSystemEntryType.video ||
      type == FileSystemEntryType.audio) {
    context.push(
      AppRoutes.mediaViewer,
      extra: MediaViewerSession(
        entry: entry,
        entries: playlist.isEmpty ? [entry] : playlist,
      ),
    );
    return;
  }

  if (isTextFile(entry.path)) {
    context.push(
      AppRoutes.textViewer,
      extra: entry,
    );
    return;
  }

  if (_isBrowsableArchiveFile(entry)) {
    context.push(
      AppRoutes.archiveViewer,
      extra: entry,
    );
    return;
  }

  showPreviewUnavailableSheet(context: context, ref: ref, entry: entry);
}

bool _isBrowsableArchiveFile(FileSystemEntry entry) {
  if (entry.isFolder) {
    return false;
  }
  final format = archiveFormatForPath(entry.path);
  return format != null && isBrowsableArchive(format);
}

/// Bottom sheet offered when [entry] cannot be previewed by any built-in
/// viewer, replacing the old dedicated "Preview unavailable" screen.
void showPreviewUnavailableSheet({
  required BuildContext context,
  required WidgetRef ref,
  required FileSystemEntry entry,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: fileIconForEntry(context, entry),
              title: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text('Preview not available'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open with'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openEntryWithSystem(context, entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: const Text('Open as'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showOpenAsSheet(context: context, ref: ref, entry: entry);
              },
            ),
          ],
        ),
      );
    },
  );
}

void _openEntryAs(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
  _OpenAsType type,
) {
  switch (type) {
    case _OpenAsType.image:
    case _OpenAsType.video:
    case _OpenAsType.audio:
      _showViewerChoiceSheet(context, ref, entry, type);
    case _OpenAsType.text:
      _showTextChoiceSheet(context, entry);
  }
}

void _showTextChoiceSheet(BuildContext context, FileSystemEntry entry) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.article_rounded, color: Color(0xFF1E88E5)),
              title: const Text('Open as Text'),
              subtitle: Text(entry.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text('Use File Explorer'),
              subtitle: const Text('Open in built-in text viewer'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(
                  AppRoutes.textViewer,
                  extra: entry,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Use other app'),
              subtitle: const Text('Choose from installed apps'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openAsSystemWithMimeType(context, entry, 'text/plain');
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showViewerChoiceSheet(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
  _OpenAsType type,
) {
  final forcedType = switch (type) {
    _OpenAsType.image => FileSystemEntryType.image,
    _OpenAsType.video => FileSystemEntryType.video,
    _OpenAsType.audio => FileSystemEntryType.audio,
    _OpenAsType.text => FileSystemEntryType.other,
  };

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(type.icon, color: Theme.of(context).colorScheme.primary),
              title: Text('Open as ${type.label}'),
              subtitle: Text(entry.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text('Use File Explorer'),
              subtitle: const Text('Open in built-in viewer'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                final forcedEntry = entry.copyWith(type: forcedType);
                openFileForPreview(
                  context: context,
                  ref: ref,
                  entry: forcedEntry,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Use other app'),
              subtitle: const Text('Choose from installed apps'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openAsSystemWithMimeType(context, entry, type.mimeType);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _openAsSystemWithMimeType(
  BuildContext context,
  FileSystemEntry entry,
  String mimeType,
) async {
  try {
    await openLocalFileWithSystem(entry.path, fallbackMimeType: mimeType);
  } on MissingPluginException {
    if (!context.mounted) return;
    _showMessage(context, 'Open with is available on Android');
  } on PlatformException catch (error) {
    if (!context.mounted) return;
    _showMessage(context, error.message ?? 'Could not open file');
  }
}

class _EntryActionsSheet extends ConsumerWidget {
  const _EntryActionsSheet({
    required this.entry,
    required this.storageVolume,
    required this.parentContext,
    required this.isSingleSelection,
  });

  final FileSystemEntry entry;
  final StorageVolume? storageVolume;
  final BuildContext parentContext;
  final bool isSingleSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferController = ref.read(transferControllerProvider.notifier);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: fileIconForEntry(context, entry),
            title: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle:
                entry.isFolder ? null : Text(detailForFileSystemEntry(entry)),
          ),
          const Divider(),
          if (!entry.isFolder) ...[
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                _shareEntry(parentContext, entry);
              },
            ),
            if (isSingleSelection)
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open with'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openEntryWithSystem(parentContext, entry);
                },
              ),
            if (isSingleSelection)
              ListTile(
                leading: const Icon(Icons.category_rounded),
                title: const Text('Open as'),
                onTap: () {
                  Navigator.of(context).pop();
                  showOpenAsSheet(
                    context: parentContext,
                    ref: ref,
                    entry: entry,
                  );
                },
              ),
            if (_isExtractableArchive(entry))
              ListTile(
                leading: const Icon(Icons.archive_rounded),
                title: const Text('Extract here'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (_isZipArchive(entry)) {
                    _extractZipEntry(parentContext, transferController, entry);
                  } else {
                    _queueEntryOperation(
                      parentContext,
                      transferController,
                      entry,
                      TransferOperation.extractArchive,
                      destinationPath: p.dirname(entry.path),
                    );
                  }
                },
              ),
          ],
          ListTile(
            leading: const Icon(Icons.inventory_2_rounded),
            title: const Text('Compress'),
            onTap: () {
              Navigator.of(context).pop();
              _showEntryCompressOptions(
                parentContext,
                transferController,
                entry,
              );
            },
          ),
          for (final operation in [
            TransferOperation.copy,
            TransferOperation.move,
            TransferOperation.rename,
          ])
            ListTile(
              leading: Icon(iconForTransferOperation(operation)),
              title: Text(operation.label),
              onTap: () async {
                Navigator.of(context).pop();
                if (operation == TransferOperation.rename) {
                  await _requestRename(
                    parentContext,
                    transferController,
                    entry,
                  );
                } else {
                  _queueEntryOperation(
                    parentContext,
                    transferController,
                    entry,
                    operation,
                  );
                }
              },
            ),
          ListTile(
            leading: Icon(
              iconForTransferOperation(TransferOperation.delete),
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              final shouldConfirm = ref
                  .read(settingsControllerProvider)
                  .settings
                  .confirmDestructiveActions;
              if (shouldConfirm) {
                await _confirmDelete(parentContext, transferController, entry);
              } else {
                _queueEntryOperation(
                  parentContext,
                  transferController,
                  entry,
                  TransferOperation.delete,
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Properties'),
            subtitle: Text(
              '${typeLabelForFileSystemEntry(entry)} - ${formatFileModifiedAt(entry.modifiedAt)}',
            ),
            onTap: () {
              Navigator.of(context).pop();
              showEntryProperties(parentContext, [entry], storageVolume);
            },
          ),
        ],
      ),
    );
  }
}

bool _isExtractableArchive(FileSystemEntry entry) {
  if (entry.isFolder) {
    return false;
  }
  return archiveFormatForPath(entry.path) != null;
}

bool _isZipArchive(FileSystemEntry entry) {
  return !entry.isFolder &&
      archiveFormatForPath(entry.path) == ArchiveFormat.zip;
}

Future<void> _extractZipEntry(
  BuildContext context,
  TransferController transferController,
  FileSystemEntry entry,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  if (!context.mounted) {
    return;
  }
  final password = await _requestArchivePassword(context, optional: true);
  if (password == null || !context.mounted) {
    return;
  }
  _queueEntryOperation(
    context,
    transferController,
    entry,
    TransferOperation.extractArchive,
    destinationPath: p.dirname(entry.path),
    archivePassword: password.isEmpty ? null : password,
  );
}

Future<void> _showEntryCompressOptions(
  BuildContext context,
  TransferController transferController,
  FileSystemEntry entry,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  if (!context.mounted) {
    return;
  }
  await showCompressOptionsSheet(
    context: context,
    transferController: transferController,
    sourcePaths: [entry.path],
    displayName: entry.name,
    destinationDirectory: p.dirname(entry.path),
    totalBytes: entry.sizeBytes,
    sourceKind: entry.isFolder
        ? FileSystemEntityType.directory
        : FileSystemEntityType.file,
  );
}

Future<bool> showCompressOptionsSheet({
  required BuildContext context,
  required TransferController transferController,
  required List<String> sourcePaths,
  required String displayName,
  required String destinationDirectory,
  int? totalBytes,
  FileSystemEntityType? sourceKind,
}) async {
  if (sourcePaths.isEmpty) {
    return false;
  }

  final singleSourceKind = sourcePaths.length == 1
      ? sourceKind ??
          await FileSystemEntity.type(
            sourcePaths.single,
            followLinks: false,
          )
      : null;
  if (!context.mounted) {
    return false;
  }
  final choices = _compressionChoicesFor(sourcePaths, singleSourceKind);
  final isSingleFile =
      sourcePaths.length == 1 && singleSourceKind == FileSystemEntityType.file;
  final defaultFileName = _defaultArchiveName(
    sourcePaths: sourcePaths,
    destinationDirectory: destinationDirectory,
  );
  final options = await showDialog<_CompressionOptions>(
    context: context,
    builder: (context) => _CompressionOptionsDialog(
      defaultFileName: defaultFileName,
      choices: choices,
      isSingleFile: isSingleFile,
    ),
  );

  if (options == null || !context.mounted) {
    return false;
  }
  final destinationPath = p.join(
    destinationDirectory,
    '${options.fileName}${options.choice.extension}',
  );
  transferController.queueOperation(
    operation: TransferOperation.compressArchive,
    sourcePaths: sourcePaths,
    displayName: displayName,
    destinationPath: destinationPath,
    totalBytes: sourcePaths.length == 1 ? totalBytes : null,
    archivePassword: options.password,
    archiveCompressionLevel: options.level.level,
  );
  _showQueuedSnackBar(context, TransferOperation.compressArchive);
  return true;
}

String _defaultArchiveName({
  required List<String> sourcePaths,
  required String destinationDirectory,
}) {
  if (sourcePaths.length == 1) {
    return p.basename(sourcePaths.single);
  }
  final folderName = p.basename(destinationDirectory);
  return folderName.isEmpty ? 'Archive' : folderName;
}

List<_CompressionChoice> _compressionChoicesFor(
  List<String> sourcePaths,
  FileSystemEntityType? singleSourceKind,
) {
  return _CompressionChoice.values;
}

Future<String?> _requestArchivePassword(
  BuildContext context, {
  bool optional = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ArchivePasswordDialog(optional: optional),
  );
}

class _CompressionOptionsDialog extends StatefulWidget {
  const _CompressionOptionsDialog({
    required this.defaultFileName,
    required this.choices,
    required this.isSingleFile,
  });

  final String defaultFileName;
  final List<_CompressionChoice> choices;
  final bool isSingleFile;

  @override
  State<_CompressionOptionsDialog> createState() =>
      _CompressionOptionsDialogState();
}

class _CompressionOptionsDialogState extends State<_CompressionOptionsDialog> {
  late final TextEditingController _fileNameController;
  late final TextEditingController _passwordController;
  late _CompressionChoice _choice;
  _CompressionLevel _level = _CompressionLevel.standard;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.defaultFileName);
    _passwordController = TextEditingController();
    _choice = widget.choices.first;
    if (!widget.isSingleFile) {
      _choice = _CompressionChoice.zip;
    }
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportsPassword = _choice.supportsPassword;
    return AlertDialog(
      title: Row(
        children: [
          const Text('Compress'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About archive formats',
            onPressed: () => _showFormatHelp(context),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fileNameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'File name',
                suffixText: _choice.extension,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_CompressionChoice>(
              initialValue: _choice,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final choice in widget.choices)
                  DropdownMenuItem(
                    value: choice,
                    enabled: !choice.singleFileOnly || widget.isSingleFile,
                    child: Text(
                      choice.singleFileOnly && !widget.isSingleFile
                          ? '${choice.label} (single file only)'
                          : choice.label,
                    ),
                  ),
              ],
              onChanged: (choice) {
                if (choice == null) {
                  return;
                }
                setState(() {
                  _choice = choice;
                  if (!choice.supportsPassword) {
                    _passwordController.clear();
                  }
                });
              },
            ),
            if (_choice.supportsLevel) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<_CompressionLevel>(
                initialValue: _level,
                decoration: const InputDecoration(labelText: 'Compress level'),
                items: [
                  for (final level in _CompressionLevel.values)
                    DropdownMenuItem(
                      value: level,
                      child: Text(level.label),
                    ),
                ],
                onChanged: (level) {
                  if (level == null) {
                    return;
                  }
                  setState(() => _level = level);
                },
              ),
            ],
            if (supportsPassword) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'Optional; ZIP only',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.inventory_2_rounded),
          label: const Text('Queue'),
        ),
      ],
    );
  }

  void _showFormatHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive formats'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFormatTable(context),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.more_horiz_rounded),
                  title: const Text('More details'),
                  children: [
                    for (final choice in widget.choices)
                      ListTile(
                        dense: true,
                        title: Text('${choice.emoji} ${choice.label}'),
                        subtitle: Text(
                          choice.singleFileOnly
                              ? '${choice.subtitle}\nSingle file only'
                              : choice.subtitle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide()),
              ),
              children: [
                SizedBox(height: 40, child: Text('Format')),
                Text('⚙️ Level'),
                Text('🔒 Password'),
              ],
            ),
            for (final choice in widget.choices)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          choice.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(choice.label),
                      ],
                    ),
                  ),
                  Text(
                    choice.supportsLevel ? '✅' : '❌',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    choice.supportsPassword ? '✅' : '❌',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  void _submit() {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty ||
        fileName.contains('/') ||
        fileName.contains('\\') ||
        fileName == '.' ||
        fileName == '..') {
      return;
    }
    final password = _choice.supportsPassword ? _passwordController.text : '';
    Navigator.of(context).pop(
      _CompressionOptions(
        fileName: fileName,
        choice: _choice,
        level: _level,
        password: password.isEmpty ? null : password,
      ),
    );
  }
}

class _ArchivePasswordDialog extends StatefulWidget {
  const _ArchivePasswordDialog({required this.optional});

  final bool optional;

  @override
  State<_ArchivePasswordDialog> createState() => _ArchivePasswordDialogState();
}

class _ArchivePasswordDialogState extends State<_ArchivePasswordDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ZIP password'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password',
          helperText: widget.optional
              ? 'Leave blank for ZIP files without a password'
              : null,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.lock_rounded),
          label: const Text('Queue'),
        ),
      ],
    );
  }

  void _submit() {
    final password = _controller.text;
    if (!widget.optional && password.isEmpty) {
      return;
    }
    Navigator.of(context).pop(password);
  }
}

Future<void> _shareEntry(BuildContext context, FileSystemEntry entry) async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);

  try {
    await shareLocalFile(entry.path);
  } on MissingPluginException {
    _showMessageWithMessenger(messenger, 'Share is available on Android');
  } on PlatformException catch (error) {
    _showMessageWithMessenger(
      messenger,
      error.message ?? 'Could not share file',
    );
  }
}

Future<void> _openEntryWithSystem(
  BuildContext context,
  FileSystemEntry entry,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);

  try {
    await openLocalFileWithSystem(entry.path);
  } on MissingPluginException {
    _showMessageWithMessenger(messenger, 'Open with is available on Android');
  } on PlatformException catch (error) {
    _showMessageWithMessenger(
      messenger,
      error.message ?? 'Could not open file',
    );
  }
}

void _queueEntryOperation(
  BuildContext context,
  TransferController transferController,
  FileSystemEntry entry,
  TransferOperation operation, {
  String? destinationPath,
  String? archivePassword,
}) {
  transferController.queueOperation(
    operation: operation,
    sourcePaths: [entry.path],
    displayName: entry.name,
    destinationPath: destinationPath,
    totalBytes: entry.sizeBytes,
    archivePassword: archivePassword,
  );
  _showQueuedSnackBar(context, operation);
}

Future<void> _requestRename(
  BuildContext context,
  TransferController transferController,
  FileSystemEntry entry,
) async {
  final controller = TextEditingController(text: entry.name);
  final newName = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Queue'),
          ),
        ],
      );
    },
  );
  controller.dispose();

  final trimmedName = newName?.trim();
  if (trimmedName == null || trimmedName.isEmpty || trimmedName == entry.name) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  _queueEntryOperation(
    context,
    transferController,
    entry,
    TransferOperation.rename,
    destinationPath: p.join(p.dirname(entry.path), trimmedName),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  TransferController transferController,
  FileSystemEntry entry,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete'),
        content: Text('Queue delete for "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Queue'),
          ),
        ],
      );
    },
  );

  if (confirmed ?? false) {
    if (!context.mounted) {
      return;
    }
    _queueEntryOperation(
      context,
      transferController,
      entry,
      TransferOperation.delete,
    );
  }
}

void _showQueuedSnackBar(
  BuildContext context,
  TransferOperation operation,
) {
  final router = GoRouter.of(context);
  _showMessage(
    context,
    '${operation.label} task queued',
    duration: const Duration(seconds: 4),
    action: SnackBarAction(
      label: 'Transfers',
      onPressed: () => router.go(AppRoutes.transfers),
    ),
  );
}

void _showMessage(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  _showMessageWithMessenger(
    ScaffoldMessenger.of(context),
    message,
    action: action,
    duration: duration,
  );
}

void _showMessageWithMessenger(
  ScaffoldMessengerState messenger,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        persist: false,
      ),
    );
}

void showEntryProperties(
  BuildContext context,
  List<FileSystemEntry> entries,
  StorageVolume? storageVolume,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return BackButtonListener(
        onBackButtonPressed: () async {
          Navigator.of(context).pop();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              entries.length == 1 ? 'Properties' : '${entries.length} items',
            ),
          ),
          body: EntryPropertiesPanel(
            entries: entries,
            storageVolume: storageVolume,
          ),
        ),
      );
    },
  );
}

class EntryPropertiesPanel extends StatefulWidget {
  const EntryPropertiesPanel({
    required this.entries,
    this.storageVolume,
    super.key,
  });

  final List<FileSystemEntry> entries;
  final StorageVolume? storageVolume;

  @override
  State<EntryPropertiesPanel> createState() => _EntryPropertiesPanelState();
}

class _EntryPropertiesPanelState extends State<EntryPropertiesPanel> {
  int? _totalSize;
  int? _totalFileCount;
  bool _sizeLoading = true;

  List<FileSystemEntry> get entries => widget.entries;
  bool get isMulti => entries.length > 1;
  FileSystemEntry get entry => entries.first;

  String get _commonParentPath {
    if (entries.isEmpty) return '/';
    if (entries.length == 1) return p.dirname(entries.first.path);
    final paths = entries.map((e) => e.path).toList();
    final parts = paths.map((p) => p.split('/')).toList();
    final minLen = parts.map((p) => p.length).reduce((a, b) => a < b ? a : b);
    var commonLen = 0;
    for (var i = 0; i < minLen; i++) {
      final segment = parts.first[i];
      if (parts.every((p) => p[i] == segment)) {
        commonLen = i + 1;
      } else {
        break;
      }
    }
    final common = parts.first.take(commonLen).join('/');
    return common.isEmpty ? '/' : common;
  }

  int get _selectedFolderCount => entries.where((e) => e.isFolder).length;

  @override
  void initState() {
    super.initState();
    _computeSize();
  }

  Future<void> _computeSize() async {
    setState(() => _sizeLoading = true);
    var totalSize = 0;
    var totalFiles = 0;
    for (final entry in entries) {
      if (entry.isFolder) {
        try {
          await for (final entity in Directory(entry.path)
              .list(recursive: true, followLinks: false)) {
            if (entity is File) {
              try {
                final stat = await entity.stat();
                totalSize += stat.size;
                totalFiles++;
              } catch (_) {}
            }
          }
        } catch (_) {}
      } else {
        totalSize += entry.sizeBytes ?? 0;
        totalFiles++;
      }
    }
    if (mounted) {
      setState(() {
        _totalSize = totalSize;
        _totalFileCount = totalFiles;
        _sizeLoading = false;
      });
    }
  }

  String _formatBytesWithCommas(int bytes) => formatCount(bytes);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMulti) ...[
              Row(
                children: [
                  fileIconForEntry(context, entry, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          typeLabelForFileSystemEntry(entry),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
            ],
            const SizedBox(height: 16),
            _PropertiesSection(
              title: isMulti ? 'Selection' : 'File Information',
              children: [
                _PropertyRow(
                  label: 'Path',
                  value: isMulti ? _commonParentPath : p.dirname(entry.path),
                ),
                if (isMulti)
                  _PropertyRow(
                    label: 'Contains',
                    value: _sizeLoading
                        ? 'Computing...'
                        : '${formatCount(_totalFileCount ?? 0)} files, ${formatCount(_selectedFolderCount)} folders',
                  ),
                if (!isMulti)
                  _PropertyRow(
                    label: 'Type',
                    value: typeLabelForFileSystemEntry(entry),
                  ),
                if (!isMulti && !entry.isFolder)
                  _PropertyRow(
                    label: 'MIME Type',
                    value: lookupMimeType(entry.path) ?? 'Unknown',
                  ),
                if (!isMulti && entry.isFolder && entry.childrenCount != null)
                  _PropertyRow(
                    label: 'Contents',
                    value: formatItemCount(entry.childrenCount!),
                  ),
                _PropertyRow(
                  label: 'Size',
                  value: _sizeLoading
                      ? 'Computing...'
                      : formatBytes(_totalSize ?? 0),
                ),
                _PropertyRow(
                  label: 'Bytes',
                  value: _sizeLoading
                      ? 'Computing...'
                      : '${_formatBytesWithCommas(_totalSize ?? 0)} bytes',
                ),
                if (!isMulti)
                  _PropertyRow(
                    label: 'Modified',
                    value: formatFileModifiedAt(entry.modifiedAt),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                _copyPathToClipboard(
                  context,
                  isMulti ? _commonParentPath : entry.path,
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy path'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PropertiesSection extends StatelessWidget {
  const _PropertiesSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

void _copyPathToClipboard(BuildContext context, String path) {
  Clipboard.setData(ClipboardData(text: path));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Path copied to clipboard')),
  );
}
