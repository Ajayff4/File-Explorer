import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageSummaryProvider = Provider<StorageSummary>((ref) {
  return const StorageSummary(
    label: 'Internal storage',
    usedBytes: 87 * 1024 * 1024 * 1024,
    totalBytes: 128 * 1024 * 1024 * 1024,
  );
});

final recentEntriesProvider = Provider<List<FileSystemEntry>>((ref) {
  final now = DateTime.now();
  return [
    FileSystemEntry(
      name: 'Camera',
      path: '/storage/emulated/0/DCIM/Camera',
      type: FileSystemEntryType.folder,
      modifiedAt: now.subtract(const Duration(minutes: 18)),
      childrenCount: 428,
    ),
    FileSystemEntry(
      name: 'Downloads',
      path: '/storage/emulated/0/Download',
      type: FileSystemEntryType.folder,
      modifiedAt: now.subtract(const Duration(hours: 2)),
      childrenCount: 91,
    ),
    FileSystemEntry(
      name: 'Holiday_clip.mp4',
      path: '/storage/emulated/0/Movies/Holiday_clip.mp4',
      type: FileSystemEntryType.video,
      modifiedAt: now.subtract(const Duration(hours: 4)),
      sizeBytes: 734 * 1024 * 1024,
    ),
    FileSystemEntry(
      name: 'Invoice_Q3.pdf',
      path: '/storage/emulated/0/Documents/Invoice_Q3.pdf',
      type: FileSystemEntryType.document,
      modifiedAt: now.subtract(const Duration(days: 1)),
      sizeBytes: 2 * 1024 * 1024,
    ),
    FileSystemEntry(
      name: 'Archive_backup.zip',
      path: '/storage/emulated/0/Download/Archive_backup.zip',
      type: FileSystemEntryType.archive,
      modifiedAt: now.subtract(const Duration(days: 3)),
      sizeBytes: 1260 * 1024 * 1024,
    ),
  ];
});
