/// A single item in the recycle bin.
class TrashItem {
  const TrashItem({
    required this.id,
    required this.originalPath,
    required this.trashPath,
    required this.name,
    required this.deletedAt,
    required this.isFolder,
    this.sizeBytes,
  });

  /// Unique id (also the on-disk name inside the trash directory).
  final String id;

  /// Where the item lived before it was trashed (empty if unknown).
  final String originalPath;

  /// Current location inside the trash directory.
  final String trashPath;

  final String name;
  final DateTime deletedAt;
  final bool isFolder;
  final int? sizeBytes;

  bool get canRestore => originalPath.isNotEmpty;
}
