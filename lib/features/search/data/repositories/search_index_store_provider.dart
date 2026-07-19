import 'package:file_explorer/features/search/data/repositories/search_index_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/search/data/repositories/search_index_store_io.dart';
import 'package:file_explorer/features/search/domain/repositories/search_index_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchIndexStoreProvider = Provider<SearchIndexStore>((ref) {
  return createSearchIndexStore(ref);
});
