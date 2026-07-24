import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';

class FakeStorageRepository implements StorageRepository {
  const FakeStorageRepository();

  static const rootPath = '/storage/emulated/0';

  @override
  Future<List<StorageVolume>> getStorageVolumes() async {
    final summary = await getPrimaryStorageSummary();
    return [
      StorageVolume(
        id: 'sample-internal',
        label: 'Internal storage',
        path: rootPath,
        summary: summary,
        isPrimary: true,
      ),
    ];
  }

  @override
  Future<StorageSummary> getPrimaryStorageSummary() async {
    return const StorageSummary(
      label: 'Internal storage',
      usedBytes: 87 * 1024 * 1024 * 1024,
      totalBytes: 128 * 1024 * 1024 * 1024,
    );
  }

  @override
  Future<DirectoryListing> listDirectory(String path) async {
    final now = DateTime.now();
    return DirectoryListing(
      path: path,
      generatedFromSampleData: true,
      volume: StorageVolume(
        id: 'sample-internal',
        label: 'Internal storage',
        path: rootPath,
        summary: await getPrimaryStorageSummary(),
        isPrimary: true,
      ),
      entries: [
        FileSystemEntry(
          name: 'Camera',
          path: '$rootPath/DCIM/Camera',
          type: FileSystemEntryType.folder,
          modifiedAt: now.subtract(const Duration(minutes: 18)),
          childrenCount: 428,
        ),
        FileSystemEntry(
          name: 'Downloads',
          path: '$rootPath/Download',
          type: FileSystemEntryType.folder,
          modifiedAt: now.subtract(const Duration(hours: 2)),
          childrenCount: 91,
        ),
        FileSystemEntry(
          name: 'Holiday_clip.mp4',
          path: '$rootPath/Movies/Holiday_clip.mp4',
          type: FileSystemEntryType.video,
          modifiedAt: now.subtract(const Duration(hours: 4)),
          sizeBytes: 734 * 1024 * 1024,
        ),
        FileSystemEntry(
          name: 'Invoice_Q3.pdf',
          path: '$rootPath/Documents/Invoice_Q3.pdf',
          type: FileSystemEntryType.document,
          modifiedAt: now.subtract(const Duration(days: 1)),
          sizeBytes: 2 * 1024 * 1024,
        ),
        FileSystemEntry(
          name: 'Archive_backup.zip',
          path: '$rootPath/Download/Archive_backup.zip',
          type: FileSystemEntryType.archive,
          modifiedAt: now.subtract(const Duration(days: 3)),
          sizeBytes: 1260 * 1024 * 1024,
        ),
      ],
    );
  }

  @override
  Future<Map<FileSystemEntryType, int>> countEntriesByType(String rootPath) async {
    // Return sample data for fake storage
    return {
      FileSystemEntryType.folder: 82,
      FileSystemEntryType.image: 1204,
      FileSystemEntryType.video: 47,
      FileSystemEntryType.audio: 156,
      FileSystemEntryType.document: 38,
      FileSystemEntryType.archive: 12,
      FileSystemEntryType.app: 64,
      FileSystemEntryType.other: 91,
    };
  }
}
