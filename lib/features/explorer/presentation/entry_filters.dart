import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';

List<FileSystemEntry> visibleExplorerEntries(
  List<FileSystemEntry> entries, {
  required bool showHiddenFiles,
}) {
  if (showHiddenFiles) {
    return entries;
  }

  return entries
      .where((entry) => !isHiddenFileSystemEntry(entry))
      .toList(growable: false);
}

bool isHiddenFileSystemEntry(FileSystemEntry entry) {
  return entry.name.startsWith('.') && entry.name.length > 1;
}
