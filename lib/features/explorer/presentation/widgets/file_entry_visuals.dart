import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';

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
    'rar' ||
    '7z' ||
    'tar' ||
    'gz' ||
    'bz2' ||
    'xz' =>
      Icons.inventory_2_rounded,
    'apk' || 'aab' => Icons.android_rounded,
    'exe' || 'msi' || 'deb' || 'rpm' => Icons.apps_rounded,
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
    'pdf' => const Color(0xFFE53935),
    'doc' || 'docx' || 'odt' || 'rtf' => const Color(0xFF1E88E5),
    'xls' || 'xlsx' || 'ods' || 'csv' => const Color(0xFF43A047),
    'ppt' || 'pptx' || 'odp' => const Color(0xFFE53935),
    'txt' || 'md' || 'log' => const Color(0xFF78909C),
    'json' || 'xml' || 'yaml' || 'yml' => const Color(0xFFFFB300),
    'html' ||
    'css' ||
    'js' ||
    'ts' ||
    'dart' ||
    'kt' ||
    'java' ||
    'py' =>
      const Color(0xFF7E57C2),
    'zip' ||
    'rar' ||
    '7z' ||
    'tar' ||
    'gz' ||
    'bz2' ||
    'xz' =>
      const Color(0xFF8D6E63),
    'apk' || 'aab' => const Color(0xFF66BB6A),
    'exe' || 'msi' || 'deb' || 'rpm' => colorScheme.primary,
    _ => switch (entry.type) {
        FileSystemEntryType.image => const Color(0xFFEC407A),
        FileSystemEntryType.video => const Color(0xFFAB47BC),
        FileSystemEntryType.audio => const Color(0xFF26A69A),
        FileSystemEntryType.document => const Color(0xFF1E88E5),
        FileSystemEntryType.archive => const Color(0xFF8D6E63),
        FileSystemEntryType.app => const Color(0xFF66BB6A),
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
