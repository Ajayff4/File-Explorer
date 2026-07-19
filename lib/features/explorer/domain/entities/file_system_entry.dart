enum FileSystemEntryType {
  folder,
  image,
  video,
  audio,
  document,
  archive,
  app,
  other,
}

class FileSystemEntry {
  const FileSystemEntry({
    required this.name,
    required this.path,
    required this.type,
    required this.modifiedAt,
    this.sizeBytes,
    this.childrenCount,
  });

  final String name;
  final String path;
  final FileSystemEntryType type;
  final DateTime modifiedAt;
  final int? sizeBytes;
  final int? childrenCount;

  bool get isFolder => type == FileSystemEntryType.folder;
}

class StorageSummary {
  const StorageSummary({
    required this.label,
    required this.usedBytes,
    required this.totalBytes,
  });

  final String label;
  final int usedBytes;
  final int totalBytes;

  double get usedFraction => usedBytes / totalBytes;
  int get freeBytes => totalBytes - usedBytes;
}

class StorageVolume {
  const StorageVolume({
    required this.id,
    required this.label,
    required this.path,
    this.summary,
    this.isPrimary = false,
  });

  final String id;
  final String label;
  final String path;
  final StorageSummary? summary;
  final bool isPrimary;
}

class DirectoryListing {
  const DirectoryListing({
    required this.path,
    required this.entries,
    this.volume,
    this.generatedFromSampleData = false,
  });

  final String path;
  final List<FileSystemEntry> entries;
  final StorageVolume? volume;
  final bool generatedFromSampleData;
}
