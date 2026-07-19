import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';

class SearchResult {
  const SearchResult({
    required this.entry,
    required this.parentPath,
    required this.depth,
  });

  final FileSystemEntry entry;
  final String parentPath;
  final int depth;
}
