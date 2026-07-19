import 'package:file_explorer/features/search/data/repositories/in_memory_search_index_store.dart';
import 'package:file_explorer/features/search/domain/repositories/search_index_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

SearchIndexStore createSearchIndexStore(Ref ref) {
  return InMemorySearchIndexStore();
}
