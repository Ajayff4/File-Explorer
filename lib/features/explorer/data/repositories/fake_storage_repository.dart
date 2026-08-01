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
    final summary = await getPrimaryStorageSummary();
    return DirectoryListing(
      path: path,
      generatedFromSampleData: true,
      volume: StorageVolume(
        id: 'sample-internal',
        label: 'Internal storage',
        path: rootPath,
        summary: summary,
        isPrimary: true,
      ),
      entries: _listingEntries(path, now),
    );
  }

  List<FileSystemEntry> _listingEntries(String path, DateTime now) {
    if (path == '$rootPath/DCIM/Camera') {
      return [
        FileSystemEntry(
          name: 'IMG_20260730.jpg',
          path: '$rootPath/DCIM/Camera/IMG_20260730.jpg',
          type: FileSystemEntryType.image,
          modifiedAt: now.subtract(const Duration(minutes: 18)),
          sizeBytes: 4 * 1024 * 1024,
        ),
        FileSystemEntry(
          name: 'Screenshot.png',
          path: '$rootPath/DCIM/Camera/Screenshot.png',
          type: FileSystemEntryType.image,
          modifiedAt: now.subtract(const Duration(hours: 3)),
          sizeBytes: 2 * 1024 * 1024,
        ),
        FileSystemEntry(
          name: 'Camera_clip.mp4',
          path: '$rootPath/DCIM/Camera/Camera_clip.mp4',
          type: FileSystemEntryType.video,
          modifiedAt: now.subtract(const Duration(hours: 5)),
          sizeBytes: 120 * 1024 * 1024,
        ),
      ];
    }

    if (path == '$rootPath/Download') {
      return [
        FileSystemEntry(
          name: 'Archive_backup.zip',
          path: '$rootPath/Download/Archive_backup.zip',
          type: FileSystemEntryType.archive,
          modifiedAt: now.subtract(const Duration(days: 3)),
          sizeBytes: 1260 * 1024 * 1024,
        ),
        FileSystemEntry(
          name: 'FileExplorer.apk',
          path: '$rootPath/Download/FileExplorer.apk',
          type: FileSystemEntryType.app,
          modifiedAt: now.subtract(const Duration(days: 4)),
          sizeBytes: 34 * 1024 * 1024,
        ),
        FileSystemEntry(
          name: 'Readme.txt',
          path: '$rootPath/Download/Readme.txt',
          type: FileSystemEntryType.document,
          modifiedAt: now.subtract(const Duration(days: 5)),
          sizeBytes: 24 * 1024,
        ),
      ];
    }

    if (path == '$rootPath/Documents') {
      return [
        FileSystemEntry(
          name: 'Invoice_Q3.pdf',
          path: '$rootPath/Documents/Invoice_Q3.pdf',
          type: FileSystemEntryType.document,
          modifiedAt: now.subtract(const Duration(days: 1)),
          sizeBytes: 2 * 1024 * 1024,
        ),
      ];
    }

    if (path == '$rootPath/Movies') {
      return [
        FileSystemEntry(
          name: 'Holiday_clip.mp4',
          path: '$rootPath/Movies/Holiday_clip.mp4',
          type: FileSystemEntryType.video,
          modifiedAt: now.subtract(const Duration(hours: 4)),
          sizeBytes: 734 * 1024 * 1024,
        ),
      ];
    }

    return [
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
        name: 'Documents',
        path: '$rootPath/Documents',
        type: FileSystemEntryType.folder,
        modifiedAt: now.subtract(const Duration(days: 1)),
        childrenCount: 38,
      ),
      FileSystemEntry(
        name: 'Movies',
        path: '$rootPath/Movies',
        type: FileSystemEntryType.folder,
        modifiedAt: now.subtract(const Duration(hours: 4)),
        childrenCount: 39,
      ),
    ];
  }

  @override
  Future<Map<FileSystemEntryType, int>> countEntriesByType(
      String rootPath) async {
    final sampleFolderCounts = <String, Map<FileSystemEntryType, int>>{
      FakeStorageRepository.rootPath: {
        FileSystemEntryType.folder: 82,
        FileSystemEntryType.image: 1204,
        FileSystemEntryType.video: 47,
        FileSystemEntryType.audio: 156,
        FileSystemEntryType.document: 38,
        FileSystemEntryType.archive: 12,
        FileSystemEntryType.app: 64,
        FileSystemEntryType.other: 91,
      },
      '${FakeStorageRepository.rootPath}/DCIM/Camera': {
        FileSystemEntryType.image: 420,
        FileSystemEntryType.video: 8,
      },
      '${FakeStorageRepository.rootPath}/Download': {
        FileSystemEntryType.archive: 12,
        FileSystemEntryType.app: 41,
        FileSystemEntryType.document: 38,
      },
      '${FakeStorageRepository.rootPath}/Documents': {
        FileSystemEntryType.document: 38,
      },
      '${FakeStorageRepository.rootPath}/Movies': {
        FileSystemEntryType.video: 39,
      },
    };

    final counts = _emptyCounts();
    counts.addAll(sampleFolderCounts[rootPath] ?? const {});
    return counts;
  }

  Map<FileSystemEntryType, int> _emptyCounts() {
    return {
      for (final type in FileSystemEntryType.values) type: 0,
    };
  }

  @override
  Future<bool> folderContainsFileType(
    String folderPath,
    FileSystemEntryType type,
  ) async {
    final sampleTypesByFolder = <String, Set<FileSystemEntryType>>{
      '$rootPath/DCIM/Camera': {
        FileSystemEntryType.image,
        FileSystemEntryType.video,
      },
      '$rootPath/Download': {
        FileSystemEntryType.archive,
        FileSystemEntryType.app,
        FileSystemEntryType.document,
      },
      '$rootPath/Documents': {
        FileSystemEntryType.document,
      },
      '$rootPath/Movies': {
        FileSystemEntryType.video,
      },
    };

    return sampleTypesByFolder[folderPath]?.contains(type) ?? false;
  }

  @override
  Future<bool> createFolder(String path) async {
    return true;
  }

  @override
  Future<bool> createFile(String path, {String content = ''}) async {
    return true;
  }
}
