import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';

enum ExplorerSortOption {
  nameAscending('Name A-Z'),
  nameDescending('Name Z-A'),
  modifiedNewest('Newest first'),
  modifiedOldest('Oldest first'),
  sizeLargest('Largest first'),
  sizeSmallest('Smallest first'),
  typeAscending('Type A-Z');

  const ExplorerSortOption(this.label);

  final String label;
}

List<FileSystemEntry> sortExplorerEntries(
  List<FileSystemEntry> entries, {
  required ExplorerSortOption option,
  bool foldersFirst = true,
}) {
  final sorted = entries.toList(growable: false)
    ..sort((left, right) {
      if (foldersFirst && left.isFolder != right.isFolder) {
        return left.isFolder ? -1 : 1;
      }

      final primary = switch (option) {
        ExplorerSortOption.nameAscending => _compareNames(left, right),
        ExplorerSortOption.nameDescending => _compareNames(right, left),
        ExplorerSortOption.modifiedNewest =>
          right.modifiedAt.compareTo(left.modifiedAt),
        ExplorerSortOption.modifiedOldest =>
          left.modifiedAt.compareTo(right.modifiedAt),
        ExplorerSortOption.sizeLargest => _compareSizes(right, left),
        ExplorerSortOption.sizeSmallest => _compareSizes(left, right),
        ExplorerSortOption.typeAscending =>
          left.type.index.compareTo(right.type.index),
      };

      if (primary != 0) {
        return primary;
      }
      return _compareNames(left, right);
    });

  return sorted;
}

int _compareNames(FileSystemEntry left, FileSystemEntry right) {
  final nameComparison = left.name.toLowerCase().compareTo(
        right.name.toLowerCase(),
      );
  if (nameComparison != 0) {
    return nameComparison;
  }
  return left.path.compareTo(right.path);
}

int _compareSizes(FileSystemEntry left, FileSystemEntry right) {
  return (left.sizeBytes ?? 0).compareTo(right.sizeBytes ?? 0);
}
