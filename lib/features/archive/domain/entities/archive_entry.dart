class ArchiveEntry {
  const ArchiveEntry({
    required this.name,
    required this.path,
    required this.isFolder,
    this.sizeBytes,
    this.modifiedAt,
    this.childrenCount,
  });

  final String name;
  final String path;
  final bool isFolder;
  final int? sizeBytes;
  final DateTime? modifiedAt;
  final int? childrenCount;

  ArchiveEntry copyWith({
    String? name,
    String? path,
    bool? isFolder,
    int? sizeBytes,
    DateTime? modifiedAt,
    int? childrenCount,
  }) {
    return ArchiveEntry(
      name: name ?? this.name,
      path: path ?? this.path,
      isFolder: isFolder ?? this.isFolder,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      childrenCount: childrenCount ?? this.childrenCount,
    );
  }
}

class ArchiveListing {
  const ArchiveListing({
    required this.archivePath,
    required this.directoryPath,
    required this.entries,
  });

  final String archivePath;
  final String directoryPath;
  final List<ArchiveEntry> entries;
}
