import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';

abstract interface class MediaLibraryRepository {
  Future<List<SearchResult>> findByType({
    required String rootPath,
    required FileSystemEntryType type,
    int maxDepth = 64,
  });

  Future<List<SearchResult>> findFoldersWithMedia({
    required String rootPath,
    required FileSystemEntryType type,
  });
}
