import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/presentation/widgets/media_thumbnail.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:file_explorer/shared/formatters/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileEntryColors {
  const FileEntryColors._();

  static const pdf = Color(0xFFE53935);
  static const document = Color(0xFF1E88E5);
  static const spreadsheet = Color(0xFF43A047);
  static const presentation = Color(0xFFE53935);
  static const text = Color(0xFF78909C);
  static const data = Color(0xFFFFB300);
  static const code = Color(0xFF7E57C2);
  static const archive = Color(0xFF8D6E63);
  static const app = Color(0xFF66BB6A);
  static const image = Color(0xFFEC407A);
  static const video = Color(0xFFAB47BC);
  static const audio = Color(0xFF26A69A);
  static const encrypted = Color(0xFF546E7A);
}

class FileTypeBadge extends StatelessWidget {
  const FileTypeBadge({
    required this.extension,
    required this.color,
    this.size = 40,
    super.key,
  });

  final String extension;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          extension.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class KindFolderIcon extends StatelessWidget {
  const KindFolderIcon({
    required this.icon,
    required this.color,
    this.size = 64,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brighter = Color.lerp(color, Colors.white, 0.18)!;
    final darker = Color.lerp(color, Colors.black, 0.22)!;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned(
            left: size * 0.14,
            top: 0,
            child: Container(
              width: size * 0.46,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: darker,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.06),
                  topRight: Radius.circular(size * 0.06),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: size * 0.11),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [brighter, color],
                  ),
                  borderRadius: BorderRadius.circular(size * 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: size * 0.08,
                      offset: Offset(0, size * 0.03),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: size * 0.44),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget fileIconForEntry(BuildContext context, FileSystemEntry entry,
    {double size = 40}) {
  if (entry.isFolder) {
    return Icon(
      Icons.folder_rounded,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  final extension = _extensionFor(entry.name);
  final color = colorForFileSystemEntry(context, entry);

  if (_shouldShowBadge(extension)) {
    return FileTypeBadge(
      extension: extension,
      color: color,
      size: size,
    );
  }

  return Icon(
    iconForFileSystemEntry(entry),
    size: size,
    color: color,
  );
}

bool _shouldShowBadge(String extension) {
  return const {
    'pdf',
    'doc',
    'docx',
    'odt',
    'rtf',
    'xls',
    'xlsx',
    'ods',
    'csv',
    'ppt',
    'pptx',
    'odp',
    'txt',
    'md',
    'log',
    'zip',
    'tar',
    'tgz',
    'tbz2',
    'txz',
    'gz',
    'bz2',
    'xz',
    'json',
    'xml',
    'yaml',
    'yml',
    'html',
    'css',
    'js',
    'ts',
    'dart',
    'kt',
    'java',
    'py',
  }.contains(extension);
}

IconData iconForFileSystemEntryType(FileSystemEntryType type) {
  return switch (type) {
    FileSystemEntryType.folder => Icons.folder_rounded,
    FileSystemEntryType.image => Icons.image_rounded,
    FileSystemEntryType.video => Icons.movie_rounded,
    FileSystemEntryType.audio => Icons.music_note_rounded,
    FileSystemEntryType.document => Icons.description_rounded,
    FileSystemEntryType.archive => Icons.inventory_2_rounded,
    FileSystemEntryType.app => Icons.apps_rounded,
    FileSystemEntryType.other => Icons.insert_drive_file_rounded,
  };
}

IconData iconForFileSystemEntry(FileSystemEntry entry) {
  if (entry.isFolder) {
    return Icons.folder_rounded;
  }

  final extension = _extensionFor(entry.name);
  return switch (extension) {
    'pdf' => Icons.picture_as_pdf_rounded,
    'doc' || 'docx' || 'odt' || 'rtf' => Icons.article_rounded,
    'xls' || 'xlsx' || 'ods' || 'csv' => Icons.table_chart_rounded,
    'ppt' || 'pptx' || 'odp' => Icons.slideshow_rounded,
    'txt' || 'md' || 'log' => Icons.notes_rounded,
    'json' || 'xml' || 'yaml' || 'yml' => Icons.data_object_rounded,
    'html' ||
    'css' ||
    'js' ||
    'ts' ||
    'dart' ||
    'kt' ||
    'java' ||
    'py' =>
      Icons.code_rounded,
    'zip' ||
    'tar' ||
    'tgz' ||
    'tbz2' ||
    'txz' ||
    'gz' ||
    'bz2' ||
    'xz' =>
      Icons.inventory_2_rounded,
    'apk' || 'apks' || 'xapk' || 'apkm' || 'aab' => Icons.android_rounded,
    'exe' || 'msi' || 'deb' || 'rpm' => Icons.apps_rounded,
    'ff4' => Icons.lock_rounded,
    _ => iconForFileSystemEntryType(entry.type),
  };
}

Color colorForFileSystemEntry(BuildContext context, FileSystemEntry entry) {
  final colorScheme = Theme.of(context).colorScheme;
  if (entry.isFolder) {
    return colorScheme.primary;
  }

  final extension = _extensionFor(entry.name);
  return switch (extension) {
    'pdf' => FileEntryColors.pdf,
    'doc' || 'docx' || 'odt' || 'rtf' => FileEntryColors.document,
    'xls' || 'xlsx' || 'ods' || 'csv' => FileEntryColors.spreadsheet,
    'ppt' || 'pptx' || 'odp' => FileEntryColors.presentation,
    'txt' || 'md' || 'log' => FileEntryColors.text,
    'json' || 'xml' || 'yaml' || 'yml' => FileEntryColors.data,
    'html' ||
    'css' ||
    'js' ||
    'ts' ||
    'dart' ||
    'kt' ||
    'java' ||
    'py' =>
      FileEntryColors.code,
    'zip' ||
    'tar' ||
    'tgz' ||
    'tbz2' ||
    'txz' ||
    'gz' ||
    'bz2' ||
    'xz' =>
      FileEntryColors.archive,
    'apk' || 'apks' || 'xapk' || 'apkm' || 'aab' => FileEntryColors.app,
    'exe' || 'msi' || 'deb' || 'rpm' => colorScheme.primary,
    'ff4' => FileEntryColors.encrypted,
    _ => switch (entry.type) {
        FileSystemEntryType.image => FileEntryColors.image,
        FileSystemEntryType.video => FileEntryColors.video,
        FileSystemEntryType.audio => FileEntryColors.audio,
        FileSystemEntryType.document => FileEntryColors.document,
        FileSystemEntryType.archive => FileEntryColors.archive,
        FileSystemEntryType.app => FileEntryColors.app,
        _ => colorScheme.onSurfaceVariant,
      },
  };
}

String detailForFileSystemEntry(FileSystemEntry entry) {
  if (entry.isFolder) {
    return '${entry.childrenCount ?? 0} items';
  }
  return formatBytes(entry.sizeBytes ?? 0);
}

String _extensionFor(String name) {
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == name.length - 1) {
    return '';
  }
  return name.substring(dotIndex + 1).toLowerCase();
}

String typeLabelForFileSystemEntry(FileSystemEntry entry) {
  return switch (entry.type) {
    FileSystemEntryType.folder => 'Folder',
    FileSystemEntryType.image => 'Image',
    FileSystemEntryType.video => 'Video',
    FileSystemEntryType.audio => 'Audio',
    FileSystemEntryType.document => 'Document',
    FileSystemEntryType.archive => 'Archive',
    FileSystemEntryType.app => 'App',
    FileSystemEntryType.other => 'File',
  };
}

String formatFileModifiedAt(DateTime modifiedAt) {
  return modifiedAt.toLocal().toString().split('.').first;
}

class GridEntryVisual extends StatelessWidget {
  const GridEntryVisual({required this.entry, super.key});

  final FileSystemEntry entry;

  @override
  Widget build(BuildContext context) {
    final iconSize = entry.isFolder ? 64.0 : 56.0;
    if (entry.type == FileSystemEntryType.image ||
        entry.type == FileSystemEntryType.video ||
        entry.type == FileSystemEntryType.app) {
      return MediaThumbnail(
        entry: entry,
        fallback: fileIconForEntry(context, entry, size: iconSize),
      );
    }

    return fileIconForEntry(context, entry, size: iconSize);
  }
}

class GridEntryTile extends ConsumerWidget {
  const GridEntryTile({
    required this.entry,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggleSelection,
    required this.onOpen,
    this.trailing,
    super.key,
  });

  final FileSystemEntry entry;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onToggleSelection;
  final VoidCallback? onOpen;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isSelectionMode ? onToggleSelection : onOpen,
        onLongPress: isSelectionMode ? null : onToggleSelection,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Center(child: GridEntryVisual(entry: entry)),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        entry.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (!entry.isFolder)
                    SizedBox(
                      height: 16,
                      child: Text(
                        detailForFileSystemEntry(entry),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelectionMode)
              Positioned(
                top: 0,
                left: 0,
                child: Checkbox(
                  visualDensity: VisualDensity.compact,
                  value: isSelected,
                  onChanged: (_) => onToggleSelection(),
                ),
              ),
            if (trailing != null && !isSelectionMode)
              Positioned(
                top: 0,
                right: 0,
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays > 365) {
    return '${(diff.inDays / 365).floor()}y ago';
  }
  if (diff.inDays > 30) {
    return '${(diff.inDays / 30).floor()}mo ago';
  }
  if (diff.inDays > 0) {
    return '${diff.inDays}d ago';
  }
  if (diff.inHours > 0) {
    return '${diff.inHours}h ago';
  }
  if (diff.inMinutes > 0) {
    return '${diff.inMinutes}m ago';
  }
  return 'Just now';
}

class FileEntryListTile extends StatelessWidget {
  const FileEntryListTile({
    required this.entry,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
    this.badgeCount,
    this.leading,
    this.trailing,
    super.key,
  });

  final FileSystemEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;
  final int? badgeCount;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final kindColor = colorForFileSystemEntry(context, entry);
    final showsThumbnail = entry.type == FileSystemEntryType.image ||
        entry.type == FileSystemEntryType.video ||
        entry.type == FileSystemEntryType.app;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isSelectionMode ? onToggleSelection : onTap,
          onLongPress:
              isSelectionMode ? null : (onLongPress ?? onToggleSelection),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      visualDensity: VisualDensity.compact,
                      value: isSelected,
                      onChanged: (_) => onToggleSelection?.call(),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: leading != null
                            ? Center(child: leading)
                            : showsThumbnail
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: MediaThumbnail(
                                      entry: entry,
                                      fallback: fileIconForEntry(context, entry,
                                          size: 56),
                                      dimension: 56,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: kindColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        iconForFileSystemEntry(entry),
                                        size: 28,
                                        color: kindColor,
                                      ),
                                    ),
                                  ),
                      ),
                      if (badgeCount != null)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            child: Text(
                              formatCount(badgeCount!),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _buildSubtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final date = formatRelativeDate(entry.modifiedAt);
    if (entry.isFolder) {
      final count = entry.childrenCount;
      if (count != null && count > 0) {
        return '${formatItemCount(count)} \u00b7 $date';
      }
      return date;
    }
    final size = formatBytes(entry.sizeBytes ?? 0);
    if (size.isNotEmpty) {
      return '$size \u00b7 $date';
    }
    return date;
  }
}
